import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'cache_manager.dart';

/// Widget hỗ trợ SWR Pattern
/// Hiển thị dữ liệu từ cache trước (nếu có), sau đó ngầm sync từ Server
class SwrBuilder<T> extends StatefulWidget {
  final String cacheKey;
  final Future<T> Function({CancelToken? cancelToken}) fetcher;
  final T Function(Map<String, dynamic> json)? fromJson;
  final Map<String, dynamic> Function(T data)? toJson;
  final Widget Function(
    BuildContext context,
    T? data,
    bool isFetching,
    dynamic error,
  )
  builder;
  final bool fetchOnMount;

  const SwrBuilder({
    super.key,
    required this.cacheKey,
    required this.fetcher,
    required this.builder,
    this.fromJson,
    this.toJson,
    this.fetchOnMount = true,
  });

  @override
  State<SwrBuilder<T>> createState() => _SwrBuilderState<T>();
}

class _SwrBuilderState<T> extends State<SwrBuilder<T>> {
  T? _data;
  bool _isFetching = false;
  dynamic _error;
  bool _hasLocalData = false;

  @override
  void initState() {
    super.initState();
    if (widget.fetchOnMount) {
      _fetchData();
    }
  }

  @override
  void didUpdateWidget(covariant SwrBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final shouldRefetchByCacheKey = oldWidget.cacheKey != widget.cacheKey;
    final shouldRefetchByFetchOnMount =
        !oldWidget.fetchOnMount && widget.fetchOnMount;

    if (shouldRefetchByCacheKey || shouldRefetchByFetchOnMount) {
      // Reset old state to avoid showing stale data for a different cache key.
      _data = null;
      _error = null;
      _hasLocalData = false;
      if (widget.fetchOnMount) {
        _fetchData();
      }
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isFetching = true;
      _error = null;
    });

    await CacheManager().fetchWithSWR<T>(
      key: widget.cacheKey,
      fetcher: widget.fetcher,
      fromJson: widget.fromJson,
      toJson: widget.toJson,
      onData: (data, isFromCache) {
        if (!mounted) return;
        setState(() {
          _data = data;
          if (isFromCache) {
            _hasLocalData = true;
          } else {
            _isFetching = false; // Ngừng fetching do server đã trả về
          }
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isFetching = false;
          // Chỉ show lỗi nếu hoàn toàn không có data
          if (!_hasLocalData) {
            _error = error;
          }
        });
      },
    );

    // Đảm bảo loading tắt kể cả khi onData đôi khi ko kịp gọi isFetching=false
    if (mounted && _isFetching && (_data != null || _error != null)) {
      setState(() {
        _isFetching = false;
      });
    }
  }

  /// Buộc load lại data (VD: pull to refresh)
  Future<void> revalidate() async {
    await _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _data, _isFetching, _error);
  }
}
