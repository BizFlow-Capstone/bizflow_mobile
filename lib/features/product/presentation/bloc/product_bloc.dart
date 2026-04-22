import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../data/product_repository.dart';
import '../../domain/entities/product_entity.dart';
import '../../../../core/reference/data/reference_item.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../core/network/api_error_message_parser.dart';
import 'product_event.dart';
import 'product_state.dart';

/// Product BLoC
/// Quản lý logic của tất cả các thao tác liên quan đến sản phẩm
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;

  ProductBloc({required this.repository}) : super(const ProductInitial()) {
    on<LoadBusinessTypesRequested>(_onLoadBusinessTypesRequested);
    on<BusinessTypesNetworkDataReceived>(_onBusinessTypesNetworkDataReceived);
    on<LoadProductsByLocationRequested>(_onLoadProductsByLocationRequested);
    on<ProductsNetworkDataReceived>(_onProductsNetworkDataReceived);
    on<ProductNetworkErrorOccurred>(_onProductNetworkErrorOccurred);
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
    on<ProductSaleItemsNetworkDataReceived>(
      _onProductSaleItemsNetworkDataReceived,
    );
    on<ImportInventoryRequested>(_onImportInventoryRequested);
    on<LoadProductDetailRequested>(_onLoadProductDetailRequested);
    on<ProductDetailNetworkDataReceived>(_onProductDetailNetworkDataReceived);
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
    try {
      final businessTypes = await repository.getBusinessTypes();
      add(BusinessTypesNetworkDataReceived(businessTypes: businessTypes));
    } catch (e) {
      debugPrint('ProductBloc._onLoadBusinessTypesRequested error: $e');
    }
  }

  Future<void> _onBusinessTypesNetworkDataReceived(
    BusinessTypesNetworkDataReceived event,
    Emitter<ProductState> emit,
  ) async {
    if (!isClosed && event.businessTypes.isNotEmpty) {
      emit(BusinessTypesLoaded(businessTypes: event.businessTypes));
    }
  }

  Future<void> _onLoadProductsByLocationRequested(
    LoadProductsByLocationRequested event,
    Emitter<ProductState> emit,
  ) async {
    final scopeKey = event.locationId;

    final localProducts = await repository.getCachedProducts(scopeKey);
    if (localProducts.isNotEmpty) {
      _products = localProducts;
      final filtered = _applyLocalFilters(
        _products,
        _searchQuery,
        _filterStatus,
        _filterBusinessTypeId,
      );
      emit(
        ProductsLoaded(
          products: filtered,
          hasReachedMax: true,
          currentPage: 1,
          locationId: event.locationId,
          searchQuery: _searchQuery,
          filterStatus: _filterStatus,
          filterBusinessTypeId: _filterBusinessTypeId,
          apiMessage: null,
        ),
      );
    } else {
      emit(const ProductLoading());
    }

    try {
      debugPrint(
        'ProductBloc: Loading master products for location ${event.locationId}',
      );
      // Fetch WITHOUT search/filter to get the master list
      final response = await repository.getProducts(
        locationId: int.tryParse(event.locationId),
        search: null,
        businessTypeId: null,
        status: null,
        pageNumber: 1,
        pageSize: 500, // Load enough for local search
      );

      final parsedProducts = _parseProductsFromResponse(response);
      final products = await _enrichProductsWithSaleItems(parsedProducts);
      _products = products;

      // Save full list to cache
      unawaited(repository.saveCachedProducts(scopeKey, products));
      unawaited(
        repository.clearProductsDirty(
          scopeKey,
          products.map((item) => item.id).toList(),
        ),
      );

      add(
        ProductsNetworkDataReceived(
          products: products,
          locationId: event.locationId,
        ),
      );
    } catch (e) {
      debugPrint('ProductBloc._onLoadProductsByLocationRequested error: $e');
      if (localProducts.isEmpty) {
        add(ProductNetworkErrorOccurred(error: e));
      }
    }
  }

  Future<void> _onProductsNetworkDataReceived(
    ProductsNetworkDataReceived event,
    Emitter<ProductState> emit,
  ) async {
    if (!isClosed) {
      final filtered = _applyLocalFilters(
        event.products,
        _searchQuery,
        _filterStatus,
        _filterBusinessTypeId,
      );
      emit(
        ProductsLoaded(
          products: filtered,
          hasReachedMax: true,
          currentPage: 1,
          locationId: event.locationId,
          searchQuery: _searchQuery,
          filterStatus: _filterStatus,
          filterBusinessTypeId: _filterBusinessTypeId,
          apiMessage: null,
        ),
      );
    }
  }

  Future<void> _onProductNetworkErrorOccurred(
    ProductNetworkErrorOccurred event,
    Emitter<ProductState> emit,
  ) async {
    if (!isClosed) {
      emit(ProductFailure(message: ApiErrorMessageParser.parse(event.error)));
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
        search: _searchQuery,
        businessTypeId: _filterBusinessTypeId,
        status: _filterStatus,
      );

      final products = await _enrichProductsWithSaleItems(
        _parseProductsFromResponse(response),
      );

      _products = products;
      await repository.saveCachedProducts(event.locationId, products);
      await repository.clearProductsDirty(
        event.locationId,
        products.map((item) => item.id).toList(),
      );
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
      emit(ProductFailure(message: ApiErrorMessageParser.parse(e)));
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
              if (normalized == 'true' ||
                  normalized == 'active' ||
                  normalized == '1') {
                return true;
              }
              if (normalized == 'false' ||
                  normalized == 'inactive' ||
                  normalized == '0') {
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

          double? parseNullableDouble(dynamic value) {
            if (value == null) return null;
            if (value is num) return value.toDouble();
            if (value is String) {
              final normalized = value.trim();
              if (normalized.isEmpty) return null;
              return double.tryParse(normalized);
            }
            return null;
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
          final double? resolvedCostPrice = parseNullableDouble(rawCostPrice);

          // 'stock' is the inventory field from the list API
          final dynamic rawQty =
              item['stock'] ??
              item['Stock'] ??
              item['quantity'] ??
              item['Quantity'] ??
              item['currentStock'] ??
              item['stock_quantity'];
          final int resolvedQty = parseInt(rawQty);

            final List<Map<String, dynamic>> resolvedSaleItems =
              (item['saleItems'] as List<dynamic>?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
              const <Map<String, dynamic>>[];

          final String? resolvedBarcode = parseString(
            item['barcode'] ?? item['Barcode'] ?? item['sku'] ?? item['Sku'],
          );

          final dynamic rawStatus = item['status'] ?? item['Status'];
          final String? resolvedStatusCode = (() {
            final code = referenceCodeFromDynamic(rawStatus).trim();
            return code.isEmpty ? null : code;
          })();
          final String? resolvedStatusLabel = referenceLabelFromDynamic(
            rawStatus,
          );
          final bool resolvedTrackInventory = parseBool(
            item['trackInventory'] ?? item['TrackInventory'] ?? true,
            fallback: true,
          );
          final bool resolvedIsActive = resolvedStatusCode != null
              ? resolvedStatusCode.toLowerCase() == 'active'
              : parseBool(
                  item['isActive'] ??
                      item['IsActive'] ??
                      item['active'] ??
                      item['Active'] ??
                      true,
                  fallback: true,
                );

          final int? resolvedLocationId = (() {
            final dynamic rawLocationId =
                item['locationId'] ?? item['LocationId'];
            if (rawLocationId == null) return null;
            return parseInt(rawLocationId, fallback: 0);
          })();

          final String? resolvedBusinessTypeId = parseString(
            item['businessTypeId'] ?? item['BusinessTypeId'],
          );

          final String? directUnit = parseString(item['unit'] ?? item['Unit']);
          final String? resolvedBaseUnit =
              directUnit ?? _resolveBaseUnitFromSaleItems(resolvedSaleItems);

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
            unit: resolvedBaseUnit,
            isActive: resolvedIsActive,
            statusLabel: resolvedStatusLabel,
            trackInventory: resolvedTrackInventory,
            saleItems: resolvedSaleItems,
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
          final resolvedBaseUnit = _resolveBaseUnitFromSaleItems(saleItems);
          return product.copyWith(
            saleItems: saleItems,
            unit: (product.unit?.trim().isNotEmpty ?? false)
                ? product.unit
                : resolvedBaseUnit,
          );
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

  String? _resolveBaseUnitFromSaleItems(List<Map<String, dynamic>> saleItems) {
    if (saleItems.isEmpty) return null;

    num? parseNum(dynamic value) {
      if (value == null) return null;
      if (value is num) return value;
      return num.tryParse(value.toString().trim());
    }

    String? parseUnit(Map<String, dynamic> item) {
      final unit = (item['baseUnit'] ??
              item['BaseUnit'] ??
              item['unitName'] ??
              item['UnitName'] ??
              item['unit'] ??
              item['Unit'])
          ?.toString()
          .trim();
      if (unit == null || unit.isEmpty) return null;
      return unit;
    }

    final baseItem = saleItems.firstWhere(
      (item) => parseNum(item['quantity'] ?? item['Quantity']) == 1,
      orElse: () => saleItems.first,
    );

    return parseUnit(baseItem);
  }

  Future<void> _onSearchProductsRequested(
    SearchProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    _searchQuery = event.query.isEmpty ? null : event.query;
    final filtered = _applyLocalFilters(
      _products,
      _searchQuery,
      _filterStatus,
      _filterBusinessTypeId,
    );
    if (state is ProductsLoaded) {
      emit(
        (state as ProductsLoaded).copyWith(
          products: filtered,
          searchQuery: _searchQuery,
        ),
      );
    }
  }

  Future<void> _onFilterProductsRequested(
    FilterProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    _filterStatus = event.status;
    _filterBusinessTypeId = event.businessTypeId;
    final filtered = _applyLocalFilters(
      _products,
      _searchQuery,
      _filterStatus,
      _filterBusinessTypeId,
    );
    if (state is ProductsLoaded) {
      emit(
        (state as ProductsLoaded).copyWith(
          products: filtered,
          filterStatus: _filterStatus,
          filterBusinessTypeId: _filterBusinessTypeId,
        ),
      );
    }
  }

  List<ProductEntity> _applyLocalFilters(
    List<ProductEntity> all,
    String? search,
    String? status,
    String? businessTypeId,
  ) {
    var result = List<ProductEntity>.from(all);

    // Filter by status
    if (status != null && status != 'ALL') {
      final bool active = status == 'ACTIVE';
      result = result.where((p) => p.isActive == active).toList();
    }

    // Filter by business type
    if (businessTypeId != null && businessTypeId != 'ALL') {
      result = result.where((p) => p.businessTypeId == businessTypeId).toList();
    }

    // Filter by search
    if (search != null && search.trim().isNotEmpty) {
      final query = search.trim().toLowerCase();
      result = result.where((p) {
        final name = p.name.toLowerCase();
        final barcode = (p.barcode ?? '').toLowerCase();
        return name.contains(query) || barcode.contains(query);
      }).toList();
    }

    return result;
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
      emit(ProductFailure(message: ApiErrorMessageParser.parse(e)));
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
        trackInventory: event.trackInventory,
        costPrice: event.costPrice ?? 0,
        price: event.salePrice,
        stock: event.trackInventory ? event.quantity : null,
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
        quantity: event.trackInventory ? (event.quantity ?? 0) : 0,
        barcode: event.barcode,
        category: event.category,
        costPrice: event.costPrice,
        salePrice: event.salePrice,
        unit: event.unit,
        trackInventory: event.trackInventory,
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
      final message = ApiErrorMessageParser.parse(e);
      debugPrint('ProductBloc._onAddProductRequested DioError: $message');
      emit(ProductFailure(message: message));
    } catch (e) {
      debugPrint('ProductBloc._onAddProductRequested error: $e');
      emit(ProductFailure(message: ApiErrorMessageParser.parse(e)));
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
        trackInventory: event.trackInventory,
        costPrice: event.costPrice,
        price: event.salePrice,
        stock: event.trackInventory ? event.quantity : null,
        priceTiers: event.priceTiers,
        imagePath: event.imagePath,
        removeImage: event.removeImage,
        manufacturer: event.manufacturer,
      );

      final index = _products.indexWhere((p) => p.id == event.productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          name: event.productName,
          quantity: event.trackInventory
              ? (event.quantity ?? _products[index].quantity)
              : 0,
          barcode: event.barcode,
          costPrice: event.costPrice,
          salePrice: event.salePrice,
          unit: event.unit,
          trackInventory: event.trackInventory,
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
                trackInventory: event.trackInventory,
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
      final message = ApiErrorMessageParser.parse(e);
      debugPrint('ProductBloc._onUpdateProductRequested DioError: $message');
      emit(ProductFailure(message: message));
    } catch (e) {
      debugPrint('ProductBloc._onUpdateProductRequested error: $e');
      emit(ProductFailure(message: ApiErrorMessageParser.parse(e)));
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
      final message = ApiErrorMessageParser.parse(e);
      debugPrint('ProductBloc._onDeleteProductRequested DioError: $message');
      emit(ProductFailure(message: message));
    } catch (e) {
      debugPrint('ProductBloc._onDeleteProductRequested error: $e');
      emit(ProductFailure(message: ApiErrorMessageParser.parse(e)));
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
      emit(ProductFailure(message: ApiErrorMessageParser.parse(e)));
    }
  }

  Future<void> _onLoadProductSaleItemsRequested(
    LoadProductSaleItemsRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final response = await repository.getProductSaleItems(event.productId);
      add(
        ProductSaleItemsNetworkDataReceived(
          saleItems: _extractSaleItems(response),
        ),
      );
    } catch (e) {
      debugPrint(
        'ProductBloc._onLoadProductSaleItemsRequested: No sale items found or error: $e',
      );
      add(ProductSaleItemsNetworkDataReceived(saleItems: []));
    }
  }

  Future<void> _onProductSaleItemsNetworkDataReceived(
    ProductSaleItemsNetworkDataReceived event,
    Emitter<ProductState> emit,
  ) async {
    if (!isClosed) {
      emit(ProductSaleItemsLoaded(saleItems: event.saleItems));
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
      emit(ProductFailure(message: ApiErrorMessageParser.parse(e)));
    }
  }

  Future<void> _onLoadProductDetailRequested(
    LoadProductDetailRequested event,
    Emitter<ProductState> emit,
  ) async {
    final cachedProduct = await repository.getCachedProductDetail(
      event.productId,
    );
    if (cachedProduct != null) {
      add(ProductDetailNetworkDataReceived(product: cachedProduct));
    }

    try {
      debugPrint(
        'ProductBloc: Background loading detail for ${event.productId}',
      );
      final product = await repository.getProductDetail(event.productId);
      add(ProductDetailNetworkDataReceived(product: product));
    } catch (e) {
      debugPrint('ProductBloc._onLoadProductDetailRequested error: $e');
      if (cachedProduct == null) {
        add(ProductDetailNetworkDataReceived(product: null));
      }
    }
  }

  Future<void> _onProductDetailNetworkDataReceived(
    ProductDetailNetworkDataReceived event,
    Emitter<ProductState> emit,
  ) async {
    if (!isClosed) {
      if (event.product != null) {
        emit(ProductDetailLoaded(product: event.product!));
      } else if (state is! ProductDetailLoaded) {
        emit(ProductFailure(message: 'Không tìm thấy chi tiết sản phẩm'));
      }
    }
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

    await repository.markProductsDirty(
      event.locationId,
      event.affectedProductIds,
    );
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
    unawaited(
      repository.clearCachedProducts().catchError((_) {
        // Database may already be closing during logout — safe to ignore.
      }),
    );
    emit(const ProductInitial());
  }

  Future<void> _updateProductCache(String locationId) async {
    await repository.saveCachedProducts(locationId, _products);
  }
}
