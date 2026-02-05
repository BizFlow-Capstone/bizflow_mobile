import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_event.dart';
import 'product_state.dart';

/// Product BLoC
/// Quản lý logic của tất cả các thao tác liên quan đến sản phẩm
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc() : super(const ProductInitial()) {
    on<LoadProductsByLocationRequested>(_onLoadProductsByLocationRequested);
    on<RefreshProductsRequested>(_onRefreshProductsRequested);
    on<SearchProductsRequested>(_onSearchProductsRequested);
    on<FilterProductsRequested>(_onFilterProductsRequested);
    on<SortProductsRequested>(_onSortProductsRequested);
    on<ClearFiltersRequested>(_onClearFiltersRequested);
    on<AddProductRequested>(_onAddProductRequested);
    on<UpdateProductRequested>(_onUpdateProductRequested);
    on<DeleteProductRequested>(_onDeleteProductRequested);
    on<ImportInventoryRequested>(_onImportInventoryRequested);
  }

  // In-memory cache for products
  List<ProductEntity> _products = [];
  List<ProductEntity> _filteredProducts = [];

  /// Mock data generator (for presentation layer without API)
  List<ProductEntity> _generateMockProducts() {
    return [
      ProductEntity(
        id: '1',
        name: 'Nước khoáng Lavie',
        barcode: '8934588020016',
        category: 'Drinks',
        costPrice: 5000,
        salePrice: 59000,
        quantity: 240,
        unit: 'Lốc',
        isActive: true,
        imageUrl: 'https://via.placeholder.com/100?text=Lavie',
        createdAt: DateTime.now(),
      ),
      ProductEntity(
        id: '2',
        name: 'Coca Cola',
        barcode: '8934588020023',
        category: 'Drinks',
        costPrice: 10000,
        salePrice: 70000,
        quantity: 180,
        unit: 'Lốc',
        isActive: true,
        imageUrl: 'https://via.placeholder.com/100?text=CocaCola',
        createdAt: DateTime.now(),
      ),
      ProductEntity(
        id: '3',
        name: 'Sprite',
        barcode: '8934588020030',
        category: 'Drinks',
        costPrice: 8000,
        salePrice: 65000,
        quantity: 150,
        unit: 'Lốc',
        isActive: true,
        imageUrl: 'https://via.placeholder.com/100?text=Sprite',
        createdAt: DateTime.now(),
      ),
    ];
  }

  Future<void> _onLoadProductsByLocationRequested(
    LoadProductsByLocationRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      // TODO: Replace with actual API call when data layer is ready
      await Future.delayed(const Duration(milliseconds: 500));
      _products = _generateMockProducts();
      _filteredProducts = List.from(_products);
      emit(ProductsLoaded(products: _filteredProducts, locationId: event.locationId));
    } catch (e) {
      emit(ProductFailure(message: e.toString()));
    }
  }

  Future<void> _onRefreshProductsRequested(
    RefreshProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      // TODO: Replace with actual API call when data layer is ready
      await Future.delayed(const Duration(milliseconds: 500));
      _products = _generateMockProducts();
      _filteredProducts = List.from(_products);
      emit(ProductsLoaded(products: _filteredProducts, locationId: event.locationId));
    } catch (e) {
      emit(ProductFailure(message: e.toString()));
    }
  }

  Future<void> _onSearchProductsRequested(
    SearchProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      if (event.query.isEmpty) {
        _filteredProducts = List.from(_products);
      } else {
        _filteredProducts = _products
            .where((product) =>
                product.name.toLowerCase().contains(event.query.toLowerCase()) ||
                (product.barcode?.toLowerCase().contains(event.query.toLowerCase()) ?? false))
            .toList();
      }
      emit(ProductsLoaded(
        products: _filteredProducts,
        locationId: event.locationId,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(ProductFailure(message: e.toString()));
    }
  }

  Future<void> _onFilterProductsRequested(
    FilterProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      _filteredProducts = _products.where((product) {
        bool statusMatch = event.status == null || 
            (event.status == 'active' ? product.isActive : !product.isActive);
        bool categoryMatch = event.category == null || product.category == event.category;
        return statusMatch && categoryMatch;
      }).toList();
      
      emit(ProductsLoaded(
        products: _filteredProducts,
        locationId: event.locationId,
        filterStatus: event.status,
        filterCategory: event.category,
      ));
    } catch (e) {
      emit(ProductFailure(message: e.toString()));
    }
  }

  Future<void> _onSortProductsRequested(
    SortProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      switch (event.sortBy) {
        case 'name':
          _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'price':
          _filteredProducts.sort((a, b) => (a.salePrice ?? 0).compareTo(b.salePrice ?? 0));
          break;
        case 'stock':
          _filteredProducts.sort((a, b) => (a.quantity ?? 0).compareTo(b.quantity ?? 0));
          break;
        case 'date':
          _filteredProducts.sort((a, b) => (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now()));
          break;
      }
      
      emit(ProductsLoaded(
        products: _filteredProducts,
        locationId: event.locationId,
        sortBy: event.sortBy,
      ));
    } catch (e) {
      emit(ProductFailure(message: e.toString()));
    }
  }

  Future<void> _onClearFiltersRequested(
    ClearFiltersRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      _filteredProducts = List.from(_products);
      emit(ProductsLoaded(products: _filteredProducts, locationId: event.locationId));
    } catch (e) {
      emit(ProductFailure(message: e.toString()));
    }
  }

  Future<void> _onAddProductRequested(
    AddProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductAddInProgress());
    try {
      // TODO: Replace with actual API call when data layer is ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      final newProduct = ProductEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: event.productName,
        barcode: event.barcode,
        category: event.category,
        costPrice: event.costPrice,
        salePrice: event.salePrice,
        quantity: event.quantity,
        unit: event.unit,
        isActive: event.isActive,
        description: event.description,
        createdAt: DateTime.now(),
      );

      _products.add(newProduct);
      _filteredProducts = List.from(_products);
      
      emit(ProductAddSuccess(product: newProduct));
    } catch (e) {
      emit(ProductFailure(message: e.toString()));
    }
  }

  Future<void> _onUpdateProductRequested(
    UpdateProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductUpdateInProgress());
    try {
      // TODO: Replace with actual API call when data layer is ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      final index = _products.indexWhere((p) => p.id == event.productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          name: event.productName,
          barcode: event.barcode,
          category: event.category,
          costPrice: event.costPrice,
          salePrice: event.salePrice,
          quantity: event.quantity,
          unit: event.unit,
          isActive: event.isActive,
          description: event.description,
        );
        _filteredProducts = List.from(_products);
        
        emit(ProductUpdateSuccess(product: _products[index]));
      }
    } catch (e) {
      emit(ProductFailure(message: e.toString()));
    }
  }

  Future<void> _onDeleteProductRequested(
    DeleteProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductDeleteInProgress());
    try {
      // TODO: Replace with actual API call when data layer is ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      _products.removeWhere((p) => p.id == event.productId);
      _filteredProducts = List.from(_products);
      
      emit(ProductDeleteSuccess(productId: event.productId));
    } catch (e) {
      emit(ProductFailure(message: e.toString()));
    }
  }

  Future<void> _onImportInventoryRequested(
    ImportInventoryRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ImportInventoryInProgress());
    try {
      // TODO: Replace with actual API call when data layer is ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      emit(ImportInventorySuccess(
        productId: event.productId,
        quantity: event.quantity,
      ));
    } catch (e) {
      emit(ProductFailure(message: e.toString()));
    }
  }
}
