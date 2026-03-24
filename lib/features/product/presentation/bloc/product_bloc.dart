import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../data/product_repository.dart';
import '../../domain/entities/product_entity.dart';
import '../../data/models/business_type_model.dart';
import '../../../../shared/cache/cache_manager.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/utils/date_formatter.dart';
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
    on<LoadProductDetailRequested>(_onLoadProductDetailRequested);
    on<ApplyLocalPriceAdjustmentRequested>(_onApplyLocalPriceAdjustment);
    on<ResetProducts>(_onResetProducts);
  }

  // In-memory cache for products
  List<ProductEntity> _products = [];

  /// Get current products list from cache
  List<ProductEntity> get currentProducts => _products;

  // Filter and search state
  String? _searchQuery;
  String? _filterStatus;
  String? _filterBusinessTypeId;

  Future<void> _onLoadBusinessTypesRequested(
    LoadBusinessTypesRequested event,
    Emitter<ProductState> emit,
  ) async {
    await CacheManager().fetchWithSWR<List<BusinessTypeDto>>(
      key: 'cache_business_types',
      fetcher: () async {
        final result = await repository.getBusinessTypes();
        if (result is List) {
          return List<BusinessTypeDto>.from(result);
        }
        return <BusinessTypeDto>[];
      },
      fromJson: (json) {
        final list = json['data'] as List;
        return list
            .map((e) => BusinessTypeDto.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      toJson: (data) {
        return {'data': data.map((e) => e.toJson()).toList()};
      },
      onData: (businessTypes, isFromCache) {
        if (businessTypes.isNotEmpty) {
          emit(BusinessTypesLoaded(businessTypes: businessTypes));
        }
      },
      onError: (e) {
        debugPrint('ProductBloc._onLoadBusinessTypesRequested error: $e');
      },
    );
  }

  Future<void> _onLoadProductsByLocationRequested(
    LoadProductsByLocationRequested event,
    Emitter<ProductState> emit,
  ) async {
    final cacheKey = 'cache_products_${event.locationId}';

    // Check if we have cached data first to decide if we show a full loading state
    final cachedData = await CacheManager().get(cacheKey);
    if (cachedData == null) {
      emit(const ProductLoading());
    }

    await CacheManager().fetchWithSWR<List<ProductEntity>>(
      key: cacheKey,
      fetcher: () async {
        debugPrint(
          'ProductBloc: Loading products for location ${event.locationId} with filters: $_searchQuery, $_filterStatus',
        );
        final response = await repository.getProducts(
          locationId: int.tryParse(event.locationId),
          search: _searchQuery,
          businessTypeId: _filterBusinessTypeId,
          status: _filterStatus,
        );
        debugPrint('ProductBloc: Response received');
        final parsedProducts = _parseProductsFromResponse(response);
        return await _enrichProductsWithSaleItems(parsedProducts);
      },
      fromJson: (json) {
        final list = json['data'] as List;
        return list
            .map((e) => ProductEntity.fromMap(e as Map<String, dynamic>))
            .toList();
      },
      toJson: (data) {
        return {'data': data.map((e) => e.toMap()).toList()};
      },
      onData: (products, isFromCache) {
        _products = products;
        emit(
          ProductsLoaded(
            products: products,
            hasReachedMax: products.length < 20,
            currentPage: 1,
            locationId: event.locationId,
            searchQuery: _searchQuery,
            filterStatus: _filterStatus,
            filterBusinessTypeId: _filterBusinessTypeId,
            apiMessage: null,
          ),
        );
      },
      onError: (e) {
        debugPrint('ProductBloc._onLoadProductsByLocationRequested error: $e');
        emit(
          ProductFailure(message: 'Failed to load products: ${e.toString()}'),
        );
      },
    );
  }

  Future<void> _onRefreshProductsRequested(
    RefreshProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      debugPrint('ProductBloc: Refreshing products');
      final response = await repository.getProducts(
        locationId: int.tryParse(event.locationId),
        search: _searchQuery,
        businessTypeId: _filterBusinessTypeId,
        status: _filterStatus,
      );

      final products = await _enrichProductsWithSaleItems(
        _parseProductsFromResponse(response),
      );

      _products = products;
      emit(
        ProductsLoaded(
          products: products,
          hasReachedMax: products.length < 20,
          currentPage: 1,
          locationId: event.locationId,
          searchQuery: _searchQuery,
          filterStatus: _filterStatus,
          filterBusinessTypeId: _filterBusinessTypeId,
          apiMessage: null, // do not show API success message for GET
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
        search: _searchQuery,
        businessTypeId: _filterBusinessTypeId,
        status: _filterStatus,
        pageNumber: nextPage,
      );

      final newProducts = await _enrichProductsWithSaleItems(
        _parseProductsFromResponse(response),
      );

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

          String? parseString(dynamic value) {
            if (value == null) return null;
            final text = value.toString().trim();
            return text.isEmpty ? null : text;
          }

          int parseInt(dynamic value, {int fallback = 0}) {
            if (value == null) return fallback;
            if (value is int) return value;
            if (value is num) return value.toInt();
            if (value is String) return int.tryParse(value.trim()) ?? fallback;
            return fallback;
          }

          bool parseBool(dynamic value, {bool fallback = true}) {
            if (value == null) return fallback;
            if (value is bool) return value;
            if (value is num) return value != 0;
            if (value is String) {
              final normalized = value.trim().toLowerCase();
              if (normalized == 'true' || normalized == 'active' || normalized == '1') {
                return true;
              }
              if (normalized == 'false' || normalized == 'inactive' || normalized == '0') {
                return false;
              }
            }
            return fallback;
          }

          final dynamic idValue =
              item['id'] ??
              item['Id'] ??
              item['ID'] ??
              item['productId'] ??
              item['ProductId'] ??
              item['product_id'];

          // API may return 'price' as the selling price and 'stock' as inventory
          final dynamic rawSalePrice =
              item['sellingPrice'] ??
              item['SellingPrice'] ??
              item['salePrice'] ??
              item['SalePrice'] ??
              item['sale_price'] ??
              item['currentSalePrice'] ??
              item['CurrentSalePrice'] ??
              item['price'] ??
              item['Price'] ??
              item['unitPrice'] ??
              item['UnitPrice'];

          double parseDouble(dynamic value) {
            if (value == null) return 0.0;
            if (value is num) return value.toDouble();
            if (value is String) return double.tryParse(value) ?? 0.0;
            return 0.0;
          }

          final double resolvedSalePrice = parseDouble(rawSalePrice);

          final dynamic rawCostPrice =
              item['costPrice'] ??
              item['CostPrice'] ??
              item['cost_price'] ??
              item['currentCostPrice'] ??
              item['CurrentCostPrice'] ??
              item['purchasePrice'] ??
              item['PurchasePrice'] ??
              item['purchase_price'] ??
              item['importPrice'] ??
              item['ImportPrice'] ??
              item['import_price'];
          final double? resolvedCostPrice = rawCostPrice == null
              ? null
              : parseDouble(rawCostPrice);

          // 'stock' is the inventory field from the list API
          final dynamic rawQty =
              item['stock'] ??
              item['Stock'] ??
              item['quantity'] ??
              item['Quantity'] ??
              item['currentStock'] ??
              item['stock_quantity'];
          final int resolvedQty = parseInt(rawQty);

          final String? resolvedBarcode = parseString(
            item['barcode'] ?? item['Barcode'] ?? item['sku'] ?? item['Sku'],
          );

          final String? resolvedStatus = parseString(item['status'] ?? item['Status']);
          final bool resolvedIsActive = resolvedStatus != null
              ? parseBool(resolvedStatus, fallback: true)
              : parseBool(
                  item['isActive'] ??
                      item['IsActive'] ??
                      item['active'] ??
                      item['Active'] ??
                      true,
                  fallback: true,
                );

          final int? resolvedLocationId = (() {
            final dynamic rawLocationId = item['locationId'] ?? item['LocationId'];
            if (rawLocationId == null) return null;
            return parseInt(rawLocationId, fallback: 0);
          })();

          final String? resolvedBusinessTypeId =
              parseString(item['businessTypeId'] ?? item['BusinessTypeId']);

          return ProductEntity(
            id: idValue?.toString() ?? '',
            name: (item['name'] ?? item['Name']) as String? ?? 'Unknown',
            description:
                (item['description'] ?? item['Description']) as String?,
            price: resolvedSalePrice,
            quantity: resolvedQty,
            imageUrl:
                (item['imageUrl'] ??
                        item['ImageUrl'] ??
                        item['image'] ??
                        item['Image'])
                    as String?,
            barcode: resolvedBarcode,
            category: (item['category'] ?? item['Category']) as String?,
            costPrice: resolvedCostPrice,
            salePrice: resolvedSalePrice,
            unit: (item['unit'] ?? item['Unit']) as String?,
            isActive: resolvedIsActive,
            createdAt: (item['createdAt'] ?? item['CreatedAt']) != null
                ? DateFormatter.parseApiDateTime(
                    (item['createdAt'] ?? item['CreatedAt']) as String?,
                  )
                : null,
            locationId: resolvedLocationId,
            businessTypeId: resolvedBusinessTypeId,
          );
        })
        .whereType<ProductEntity>()
        .toList();
  }

  Future<List<ProductEntity>> _enrichProductsWithSaleItems(
    List<ProductEntity> products,
  ) async {
    if (products.isEmpty) return products;

    final enriched = await Future.wait(
      products.map((product) async {
        if (product.saleItems.isNotEmpty) {
          return product;
        }

        try {
          final raw = await repository.getProductSaleItems(product.id);
          final saleItems = _extractSaleItems(raw);
          if (saleItems.isEmpty) return product;
          return product.copyWith(saleItems: saleItems);
        } catch (e) {
          debugPrint(
            'ProductBloc: Failed to load sale items for product ${product.id}: $e',
          );
          return product;
        }
      }),
    );

    return enriched;
  }

  List<Map<String, dynamic>> _extractSaleItems(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (data is Map<String, dynamic> && data['saleItems'] is List) {
        return (data['saleItems'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    if (response is List) {
      return response
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return <Map<String, dynamic>>[];
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
    _filterBusinessTypeId = event.businessTypeId;
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
          filterBusinessTypeId: _filterBusinessTypeId,
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
    _filterBusinessTypeId = null;
    add(LoadProductsByLocationRequested(locationId: event.locationId));
  }

  Future<void> _onAddProductRequested(
    AddProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductAddInProgress());
    try {
      debugPrint('ProductBloc: Creating product: ${event.productName}');
      debugPrint(
        'Event CostPrice: ${event.costPrice}, SalePrice: ${event.salePrice}',
      );

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
        price: event.salePrice,
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

      // Update cache
      await _updateProductCache(event.locationId);

      emit(ProductAddSuccess(product: newProduct));
      emit(
        ProductsLoaded(
          products: _products,
          hasReachedMax: state is ProductsLoaded
              ? (state as ProductsLoaded).hasReachedMax
              : false,
          currentPage: state is ProductsLoaded
              ? (state as ProductsLoaded).currentPage
              : 1,
          locationId: event.locationId,
        ),
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? e.toString();
      debugPrint('ProductBloc._onAddProductRequested DioError: $message');
      emit(ProductFailure(message: message.toString()));
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
        price: event.salePrice,
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

        // Update cache
        await _updateProductCache(locationId.toString());

        emit(ProductUpdateSuccess(product: _products[index]));
        emit(
          ProductsLoaded(
            products: _products,
            hasReachedMax: state is ProductsLoaded
                ? (state as ProductsLoaded).hasReachedMax
                : false,
            currentPage: state is ProductsLoaded
                ? (state as ProductsLoaded).currentPage
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
            hasReachedMax: state is ProductsLoaded
                ? (state as ProductsLoaded).hasReachedMax
                : false,
            currentPage: state is ProductsLoaded
                ? (state as ProductsLoaded).currentPage
                : 1,
            locationId: locationId.toString(),
          ),
        );
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? e.toString();
      debugPrint('ProductBloc._onUpdateProductRequested DioError: $message');
      emit(ProductFailure(message: message.toString()));
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

      // Update cache
      await _updateProductCache(event.locationId);

      emit(ProductDeleteSuccess(productId: event.productId));
      emit(
        ProductsLoaded(
          products: _products,
          hasReachedMax: state is ProductsLoaded
              ? (state as ProductsLoaded).hasReachedMax
              : false,
          currentPage: state is ProductsLoaded
              ? (state as ProductsLoaded).currentPage
              : 1,
          locationId: event.locationId,
        ),
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? e.toString();
      debugPrint('ProductBloc._onDeleteProductRequested DioError: $message');
      emit(ProductFailure(message: message.toString()));
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
            hasReachedMax: state is ProductsLoaded
                ? (state as ProductsLoaded).hasReachedMax
                : false,
            currentPage: state is ProductsLoaded
                ? (state as ProductsLoaded).currentPage
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
            hasReachedMax: state is ProductsLoaded
                ? (state as ProductsLoaded).hasReachedMax
                : false,
            currentPage: state is ProductsLoaded
                ? (state as ProductsLoaded).currentPage
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
    final businessId = BusinessContext().currentBusinessId ?? 'all';
    final cacheKey = 'cache_sale_items_${businessId}_${event.productId}';

    await CacheManager().fetchWithSWR<List<Map<String, dynamic>>>(
      key: cacheKey,
      fetcher: () async {
        final response = await repository.getProductSaleItems(event.productId);
        return _extractSaleItems(response);
      },
      fromJson: (json) {
        final list = json['data'];
        if (list is! List) return <Map<String, dynamic>>[];
        return list.whereType<Map<String, dynamic>>().toList();
      },
      toJson: (data) {
        return {'data': data};
      },
      onData: (saleItems, _) {
        emit(ProductSaleItemsLoaded(saleItems: saleItems));
      },
      onError: (e) {
        debugPrint(
          'ProductBloc._onLoadProductSaleItemsRequested: No sale items found or error: $e',
        );
        emit(const ProductSaleItemsLoaded(saleItems: []));
      },
    );
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

  Future<void> _onLoadProductDetailRequested(
    LoadProductDetailRequested event,
    Emitter<ProductState> emit,
  ) async {
    final cacheKey = 'cache_product_detail_${event.productId}';

    await CacheManager().fetchWithSWR<ProductEntity?>(
      key: cacheKey,
      fetcher: () async {
        debugPrint(
          'ProductBloc: Background loading detail for ${event.productId}',
        );
        return await repository.getProductDetail(event.productId);
      },
      fromJson: (json) {
        return ProductEntity.fromMap(json);
      },
      toJson: (product) {
        return product?.toMap() ?? {};
      },
      onData: (product, isFromCache) {
        if (product != null) {
          emit(ProductDetailLoaded(product: product));
        }
      },
      onError: (e) {
        debugPrint('ProductBloc._onLoadProductDetailRequested error: $e');
        if (state is! ProductDetailLoaded) {
          emit(
            ProductFailure(
              message: 'Failed to load product detail: ${e.toString()}',
            ),
          );
        }
      },
    );
  }

  Future<void> _onApplyLocalPriceAdjustment(
    ApplyLocalPriceAdjustmentRequested event,
    Emitter<ProductState> emit,
  ) async {
    if (_products.isEmpty || event.affectedProductIds.isEmpty) {
      return;
    }

    double clampNonNegative(double value) => value < 0 ? 0 : value;

    _products = _products.map((product) {
      if (!event.affectedProductIds.contains(product.id)) {
        return product;
      }

      final baseSalePrice = product.salePrice ?? product.price;
      final nextSalePrice = clampNonNegative(baseSalePrice + event.deltaAmount);

      return product.copyWith(salePrice: nextSalePrice, price: nextSalePrice);
    }).toList();

    await _updateProductCache(event.locationId);

    emit(
      ProductsLoaded(
        products: _products,
        hasReachedMax: _products.length < 20,
        currentPage: 1,
        locationId: event.locationId,
        searchQuery: _searchQuery,
        filterStatus: _filterStatus,
        filterBusinessTypeId: _filterBusinessTypeId,
        apiMessage: null,
      ),
    );
  }

  void _onResetProducts(ResetProducts event, Emitter<ProductState> emit) {
    _products = [];
    _searchQuery = null;
    _filterStatus = null;
    _filterBusinessTypeId = null;
    emit(const ProductInitial());
  }

  Future<void> _updateProductCache(String locationId) async {
    final cacheKey = 'cache_products_$locationId';
    await CacheManager().set(cacheKey, {
      'data': _products.map((e) => e.toMap()).toList(),
    });
  }
}
