import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/product_repository.dart';
import '../../domain/entities/product_entity.dart';
import '../../data/models/business_type_model.dart';
import 'product_event.dart';
import 'product_state.dart';

/// Product BLoC
/// Quản lý logic của tất cả các thao tác liên quan đến sản phẩm
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;

  ProductBloc({required this.repository}) : super(const ProductInitial()) {
    on<LoadBusinessTypesRequested>(_onLoadBusinessTypesRequested);
    on<LoadProductsByLocationRequested>(_onLoadProductsByLocationRequested);
    on<RefreshProductsRequested>(_onRefreshProductsRequested);
    on<SearchProductsRequested>(_onSearchProductsRequested);
    on<FilterProductsRequested>(_onFilterProductsRequested);
    on<SortProductsRequested>(_onSortProductsRequested);
    on<ClearFiltersRequested>(_onClearFiltersRequested);
    on<LoadMoreProductsRequested>(_onLoadMoreProductsRequested);
    on<AddProductRequested>(_onAddProductRequested);
    on<UpdateProductRequested>(_onUpdateProductRequested);
    on<DeleteProductRequested>(_onDeleteProductRequested);
    on<UpdateProductStatusRequested>(_onUpdateProductStatusRequested);
    on<LoadProductSaleItemsRequested>(_onLoadProductSaleItemsRequested);
    on<ImportInventoryRequested>(_onImportInventoryRequested);
  }

  // In-memory cache for products
  List<ProductEntity> _products = [];

  /// Get current products list from cache
  List<ProductEntity> get currentProducts => _products;

  // Filter and search state
  String? _searchQuery;
  String? _filterStatus;
  String? _filterCategory;

  Future<void> _onLoadBusinessTypesRequested(
    LoadBusinessTypesRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final businessTypes = await repository.getBusinessTypes();
      if (businessTypes is List && businessTypes.isNotEmpty) {
        emit(
          BusinessTypesLoaded(
            businessTypes: List<BusinessTypeDto>.from(businessTypes),
          ),
        );
      }
    } catch (e) {
      debugPrint('ProductBloc._onLoadBusinessTypesRequested error: $e');
    }
  }

  Future<void> _onLoadProductsByLocationRequested(
    LoadProductsByLocationRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      debugPrint(
        'ProductBloc: Loading products for location ${event.locationId} with filters: $_searchQuery, $_filterStatus',
      );

      final response = await repository.getProducts(
        locationId: int.tryParse(event.locationId),
        name: _searchQuery,
        sku: _searchQuery,
        status: _filterStatus,
      );

      debugPrint('ProductBloc: Response received');

      final products = _parseProductsFromResponse(response);

      _products = products;
      emit(
        ProductsLoaded(
          products: products,
          hasReachedMax: products.length < 20,
          currentPage: 1,
          locationId: event.locationId,
          searchQuery: _searchQuery,
          filterStatus: _filterStatus,
          filterCategory: _filterCategory,
          apiMessage: response is Map ? response['message'] as String? : null,
        ),
      );
    } catch (e) {
      debugPrint('ProductBloc._onLoadProductsByLocationRequested error: $e');
      emit(ProductFailure(message: 'Failed to load products: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshProductsRequested(
    RefreshProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      debugPrint('ProductBloc: Refreshing products');
      final response = await repository.getProducts(
        locationId: int.tryParse(event.locationId),
        name: _searchQuery,
        sku: _searchQuery,
        status: _filterStatus,
      );

      final products = _parseProductsFromResponse(response);

      _products = products;
      emit(
        ProductsLoaded(
          products: products,
          hasReachedMax: products.length < 20,
          currentPage: 1,
          locationId: event.locationId,
          searchQuery: _searchQuery,
          filterStatus: _filterStatus,
          filterCategory: _filterCategory,
          apiMessage: response is Map ? response['message'] as String? : null,
        ),
      );
    } catch (e) {
      debugPrint('ProductBloc._onRefreshProductsRequested error: $e');
      emit(
        ProductFailure(message: 'Failed to refresh products: ${e.toString()}'),
      );
    }
  }

  Future<void> _onLoadMoreProductsRequested(
    LoadMoreProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    final state = this.state;
    if (state is! ProductsLoaded || state.hasReachedMax) return;

    try {
      final nextPage = state.currentPage + 1;
      debugPrint('ProductBloc: Loading more products, page: $nextPage');

      final response = await repository.getProducts(
        locationId: int.tryParse(event.locationId),
        name: _searchQuery,
        sku: _searchQuery,
        status: _filterStatus,
        pageNumber: nextPage,
      );

      final newProducts = _parseProductsFromResponse(response);

      if (newProducts.isEmpty) {
        emit(state.copyWith(hasReachedMax: true));
      } else {
        _products.addAll(newProducts);
        emit(
          state.copyWith(
            products: List.of(state.products)..addAll(newProducts),
            currentPage: nextPage,
            hasReachedMax: newProducts.length < 20, // Assuming PageSize is 20
          ),
        );
      }
    } catch (e) {
      debugPrint('ProductBloc._onLoadMoreProductsRequested error: $e');
      // Don't emit failure here to avoid breaking the UI, just log it
    }
  }

  /// Helper to parse products from API response
  List<ProductEntity> _parseProductsFromResponse(dynamic response) {
    if (response is! Map<String, dynamic>) return [];

    final dynamic dataField = response['data'];
    List<dynamic> productsList = [];

    if (dataField is List<dynamic>) {
      productsList = dataField;
    } else if (dataField is Map<String, dynamic>) {
      productsList =
          dataField['items'] ??
          dataField['products'] ??
          dataField['data'] ??
          [];
    }

    return productsList
        .map((item) {
          if (item is! Map<String, dynamic>) return null;
          final dynamic idValue =
              item['id'] ??
              item['Id'] ??
              item['ID'] ??
              item['productId'] ??
              item['ProductId'] ??
              item['product_id'];

          // API may return 'price' as the selling price and 'stock' as inventory
          final dynamic rawSalePrice =
              item['salePrice'] ??
              item['SalePrice'] ??
              item['price'] ??
              item['Price'];
          final double resolvedSalePrice =
              (rawSalePrice as num?)?.toDouble() ?? 0.0;

          final dynamic rawCostPrice = item['costPrice'] ?? item['CostPrice'];
          final double? resolvedCostPrice = (rawCostPrice as num?)?.toDouble();

          // 'stock' is the inventory field from the list API
          final dynamic rawQty =
              item['stock'] ??
              item['Stock'] ??
              item['quantity'] ??
              item['Quantity'];
          final int resolvedQty = (rawQty as num?)?.toInt() ?? 0;

          return ProductEntity(
            id: idValue?.toString() ?? '',
            name: (item['name'] ?? item['Name']) as String? ?? 'Unknown',
            description:
                (item['description'] ?? item['Description']) as String?,
            price: resolvedSalePrice,
            quantity: resolvedQty,
            imageUrl: (item['imageUrl'] ?? item['ImageUrl']) as String?,
            barcode:
                (item['barcode'] ??
                        item['Barcode'] ??
                        item['sku'] ??
                        item['Sku'])
                    as String?,
            category: (item['category'] ?? item['Category']) as String?,
            costPrice: resolvedCostPrice,
            salePrice: resolvedSalePrice,
            unit: (item['unit'] ?? item['Unit']) as String?,
            isActive: (item['status'] ?? item['Status']) != null
                ? ((item['status'] ?? item['Status']) == 'active')
                : (item['isActive'] ??
                          item['IsActive'] ??
                          item['active'] ??
                          item['Active'] ??
                          true)
                      as bool,
            createdAt: (item['createdAt'] ?? item['CreatedAt']) != null
                ? DateTime.tryParse(
                    (item['createdAt'] ?? item['CreatedAt']) as String,
                  )
                : null,
            locationId:
                item['locationId'] as int? ?? item['LocationId'] as int?,
            businessTypeId:
                (item['businessTypeId'] ?? item['BusinessTypeId']) as String?,
          );
        })
        .whereType<ProductEntity>()
        .toList();
  }

  Future<void> _onSearchProductsRequested(
    SearchProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    _searchQuery = event.query.isEmpty ? null : event.query;
    add(LoadProductsByLocationRequested(locationId: event.locationId));
  }

  Future<void> _onFilterProductsRequested(
    FilterProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    _filterStatus = event.status;
    _filterCategory = event.category;
    add(LoadProductsByLocationRequested(locationId: event.locationId));
  }

  Future<void> _onSortProductsRequested(
    SortProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      debugPrint('ProductBloc: Sorting products by: ${event.sortBy}');

      List<ProductEntity> sorted = List.from(_products);
      switch (event.sortBy) {
        case 'name':
          sorted.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'price':
          sorted.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'stock':
          sorted.sort((a, b) => a.quantity.compareTo(b.quantity));
          break;
        case 'date':
          sorted.sort((a, b) => b.id.compareTo(a.id));
          break;
      }

      emit(
        ProductsLoaded(
          products: sorted,
          locationId: event.locationId,
          searchQuery: _searchQuery,
          filterStatus: _filterStatus,
          filterCategory: _filterCategory,
          sortBy: event.sortBy,
        ),
      );
    } catch (e) {
      debugPrint('ProductBloc._onSortProductsRequested error: $e');
      emit(ProductFailure(message: 'Failed to sort products: ${e.toString()}'));
    }
  }

  Future<void> _onClearFiltersRequested(
    ClearFiltersRequested event,
    Emitter<ProductState> emit,
  ) async {
    _searchQuery = null;
    _filterStatus = null;
    _filterCategory = null;
    add(LoadProductsByLocationRequested(locationId: event.locationId));
  }

  Future<void> _onAddProductRequested(
    AddProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductAddInProgress());
    try {
      debugPrint('ProductBloc: Creating product: ${event.productName}');

      // If businessTypeId is not provided, try to find one from existing products at this location
      String? bId;
      try {
        final existing = _products.firstWhere(
          (p) =>
              p.locationId.toString() == event.locationId.toString() &&
              p.businessTypeId != null,
        );
        bId = existing.businessTypeId;
      } catch (_) {}

      // Fallback to a valid UUID strings - required by endpoint.md
      final businessTypeId =
          event.businessTypeId ?? bId ?? '00000000-0000-0000-0000-000000000000';

      final response = await repository.createProduct(
        productName: event.productName,
        unit: event.unit ?? 'piece',
        businessTypeId: businessTypeId,
        locationId: int.tryParse(event.locationId) ?? 1,
        sku: event.barcode,
        costPrice: event.costPrice ?? 0,
        stock: event.quantity,
        priceTiers: event.priceTiers,
        imagePath: event.imagePath,
        manufacturer: event.manufacturer,
      );

      debugPrint('ProductBloc: Create response: $response');

      final dynamic idValue = response is Map
          ? (response['id'] ??
                response['Id'] ??
                response['ID'] ??
                response['data']?['id'] ??
                response['data']?['Id'])
          : null;
      final newProduct = ProductEntity(
        id: idValue?.toString() ?? '${DateTime.now().millisecondsSinceEpoch}',
        name: event.productName,
        description: event.description ?? '',
        price: event.salePrice ?? 0,
        quantity: event.quantity ?? 0,
        barcode: event.barcode,
        category: event.category,
        costPrice: event.costPrice,
        salePrice: event.salePrice,
        unit: event.unit,
        isActive: event.isActive,
        createdAt: DateTime.now(),
        businessTypeId: event.businessTypeId,
        manufacturer: event.manufacturer,
      );

      _products.add(newProduct);

      emit(ProductAddSuccess(product: newProduct));
      emit(
        ProductsLoaded(
          products: _products,
          hasReachedMax: this.state is ProductsLoaded
              ? (this.state as ProductsLoaded).hasReachedMax
              : false,
          currentPage: this.state is ProductsLoaded
              ? (this.state as ProductsLoaded).currentPage
              : 1,
          locationId: event.locationId,
        ),
      );
    } catch (e) {
      debugPrint('ProductBloc._onAddProductRequested error: $e');
      emit(ProductFailure(message: 'Failed to add product: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProductRequested(
    UpdateProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductUpdateInProgress());
    try {
      debugPrint('ProductBloc: Updating product: ${event.productId}');

      // Get existing product to retrieve businessTypeId and locationId if not in event
      final existingProduct = _products.firstWhere(
        (p) => p.id == event.productId,
        orElse: () => throw Exception('Product not found in local state'),
      );

      final businessTypeId =
          event.businessTypeId ??
          existingProduct.businessTypeId ??
          '00000000-0000-0000-0000-000000000000';
      final locationId =
          int.tryParse(event.locationId) ?? existingProduct.locationId ?? 0;

      await repository.updateProduct(
        event.productId,
        productName: event.productName,
        unit: event.unit ?? existingProduct.unit ?? 'Unit',
        locationId: locationId,
        businessTypeId: businessTypeId,
        sku: event.barcode,
        costPrice: event.costPrice,
        stock: event.quantity,
        priceTiers: event.priceTiers,
        imagePath: event.imagePath,
        removeImage: event.removeImage,
        manufacturer: event.manufacturer,
      );

      final index = _products.indexWhere((p) => p.id == event.productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          name: event.productName,
          quantity: event.quantity,
          barcode: event.barcode,
          costPrice: event.costPrice,
          salePrice: event.salePrice,
          unit: event.unit,
          isActive: event.isActive,
          description: event.description,
        );

        emit(ProductUpdateSuccess(product: _products[index]));
        emit(
          ProductsLoaded(
            products: _products,
            hasReachedMax: this.state is ProductsLoaded
                ? (this.state as ProductsLoaded).hasReachedMax
                : false,
            currentPage: this.state is ProductsLoaded
                ? (this.state as ProductsLoaded).currentPage
                : 1,
            locationId: locationId.toString(),
          ),
        );
      } else {
        emit(
          ProductUpdateSuccess(
            product: ProductEntity(
              id: event.productId,
              name: event.productName,
              description: event.description ?? '',
              price: event.salePrice ?? 0,
              quantity: event.quantity ?? 0,
              barcode: event.barcode,
              category: event.category,
              costPrice: event.costPrice,
              salePrice: event.salePrice,
              unit: event.unit,
              isActive: event.isActive,
              businessTypeId:
                  event.businessTypeId ?? existingProduct.businessTypeId,
              manufacturer: event.manufacturer ?? existingProduct.manufacturer,
            ),
          ),
        );
        emit(
          ProductsLoaded(
            products: _products,
            hasReachedMax: this.state is ProductsLoaded
                ? (this.state as ProductsLoaded).hasReachedMax
                : false,
            currentPage: this.state is ProductsLoaded
                ? (this.state as ProductsLoaded).currentPage
                : 1,
            locationId: locationId.toString(),
          ),
        );
      }
    } catch (e) {
      debugPrint('ProductBloc._onUpdateProductRequested error: $e');
      emit(
        ProductFailure(message: 'Failed to update product: ${e.toString()}'),
      );
    }
  }

  Future<void> _onDeleteProductRequested(
    DeleteProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductDeleteInProgress());
    try {
      debugPrint('ProductBloc: Deleting product: ${event.productId}');

      await repository.deleteProduct(event.productId);

      _products.removeWhere((p) => p.id == event.productId);

      emit(ProductDeleteSuccess(productId: event.productId));
      emit(
        ProductsLoaded(
          products: _products,
          hasReachedMax: this.state is ProductsLoaded
              ? (this.state as ProductsLoaded).hasReachedMax
              : false,
          currentPage: this.state is ProductsLoaded
              ? (this.state as ProductsLoaded).currentPage
              : 1,
          locationId: event.locationId,
        ),
      );
    } catch (e) {
      debugPrint('ProductBloc._onDeleteProductRequested error: $e');
      emit(
        ProductFailure(message: 'Failed to delete product: ${e.toString()}'),
      );
    }
  }

  Future<void> _onUpdateProductStatusRequested(
    UpdateProductStatusRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductUpdateInProgress());
    try {
      debugPrint(
        'ProductBloc: Updating product status: ${event.productId} to ${event.isActive}',
      );

      await repository.updateProductStatus(
        event.productId,
        status: event.isActive,
      );

      final index = _products.indexWhere((p) => p.id == event.productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(isActive: event.isActive);
        emit(ProductUpdateSuccess(product: _products[index]));
        emit(
          ProductsLoaded(
            products: _products,
            hasReachedMax: this.state is ProductsLoaded
                ? (this.state as ProductsLoaded).hasReachedMax
                : false,
            currentPage: this.state is ProductsLoaded
                ? (this.state as ProductsLoaded).currentPage
                : 1,
            locationId: _products[index].locationId?.toString() ?? '1',
          ),
        );
      } else {
        // If not in cache, we just emit success with a skeleton entity
        emit(
          ProductUpdateSuccess(
            product: ProductEntity(
              id: event.productId,
              name: '',
              price: 0,
              quantity: 0,
              isActive: event.isActive,
            ),
          ),
        );
        emit(
          ProductsLoaded(
            products: _products,
            hasReachedMax: this.state is ProductsLoaded
                ? (this.state as ProductsLoaded).hasReachedMax
                : false,
            currentPage: this.state is ProductsLoaded
                ? (this.state as ProductsLoaded).currentPage
                : 1,
            locationId: '1',
          ),
        );
      }
    } catch (e) {
      debugPrint('ProductBloc._onUpdateProductStatusRequested error: $e');
      emit(
        ProductFailure(
          message: 'Failed to update product status: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onLoadProductSaleItemsRequested(
    LoadProductSaleItemsRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      debugPrint(
        'ProductBloc: Loading sale items for product: ${event.productId}',
      );

      final response = await repository.getProductSaleItems(event.productId);

      debugPrint('ProductBloc: Sale items response: $response');

      // Parse sale items from response
      List<Map<String, dynamic>> saleItems = [];
      if (response is List<dynamic>) {
        saleItems = response.map((item) {
          if (item is Map<String, dynamic>) {
            return {
              'Unit': item['unit'] as String? ?? '',
              'Quantity': item['quantity'] as int? ?? 0,
              'Price': item['price'] as num? ?? 0,
            };
          }
          return <String, dynamic>{};
        }).toList();
      } else if (response is Map<String, dynamic>) {
        final data = response['data'];
        List<dynamic> itemsList = [];

        if (data is List<dynamic>) {
          itemsList = data;
        } else if (data is Map<String, dynamic> &&
            data['saleItems'] is List<dynamic>) {
          itemsList = data['saleItems'] as List<dynamic>;
        }

        if (itemsList.isNotEmpty) {
          saleItems = itemsList.map((item) {
            if (item is Map<String, dynamic>) {
              return {
                'Unit': item['unit'] as String? ?? '',
                'Quantity': item['quantity'] as int? ?? 0,
                'Price': item['price'] as num? ?? 0,
              };
            }
            return <String, dynamic>{};
          }).toList();
        }
      }

      emit(ProductSaleItemsLoaded(saleItems: saleItems));
    } catch (e) {
      debugPrint(
        'ProductBloc._onLoadProductSaleItemsRequested: No sale items found or error: $e',
      );
      // Treat as empty list if loading fails (e.g., 404 not found is common if no tiers exist)
      emit(const ProductSaleItemsLoaded(saleItems: []));
    }
  }

  Future<void> _onImportInventoryRequested(
    ImportInventoryRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ImportInventoryInProgress());
    try {
      debugPrint(
        'ProductBloc: Importing inventory for product: ${event.productId}',
      );

      emit(
        ImportInventorySuccess(
          productId: event.productId,
          quantity: event.quantity,
        ),
      );
    } catch (e) {
      debugPrint('ProductBloc._onImportInventoryRequested error: $e');
      emit(
        ProductFailure(message: 'Failed to import inventory: ${e.toString()}'),
      );
    }
  }
}
