/// List Extensions
extension ListExtension<T> on List<T> {
  /// Get first element or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last element or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Get element at index or null
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Safe sublist
  List<T> safeSublist(int start, [int? end]) {
    if (start >= length) return [];
    final actualEnd = end != null && end < length ? end : length;
    return sublist(start, actualEnd);
  }

  /// Add if not exists
  void addIfNotExists(T item) {
    if (!contains(item)) add(item);
  }

  /// Toggle item (add if not exists, remove if exists)
  void toggle(T item) {
    if (contains(item)) {
      remove(item);
    } else {
      add(item);
    }
  }

  /// Replace item at index
  void replaceAt(int index, T item) {
    if (index >= 0 && index < length) {
      this[index] = item;
    }
  }

  /// Replace item
  void replaceWhere(bool Function(T) test, T newItem) {
    final index = indexWhere(test);
    if (index != -1) {
      this[index] = newItem;
    }
  }

  /// Update item
  void updateWhere(bool Function(T) test, T Function(T) update) {
    final index = indexWhere(test);
    if (index != -1) {
      this[index] = update(this[index]);
    }
  }

  /// Chunk list into smaller lists
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      final end = (i + size < length) ? i + size : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }

  /// Separate with separator
  List<T> separatedBy(T separator) {
    if (isEmpty) return [];
    final result = <T>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) {
        result.add(separator);
      }
    }
    return result;
  }
}

/// Nullable List Extensions
extension NullableListExtension<T> on List<T>? {
  /// Check if list is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Check if list is not null and not empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  /// Return empty list if null
  List<T> get orEmpty => this ?? [];

  /// Return length or 0 if null
  int get lengthOrZero => this?.length ?? 0;
}

/// Map Extensions
extension MapExtension<K, V> on Map<K, V> {
  /// Get value or default
  V getOrDefault(K key, V defaultValue) {
    return containsKey(key) ? this[key]! : defaultValue;
  }

  /// Get value or null
  V? getOrNull(K key) {
    return containsKey(key) ? this[key] : null;
  }

  /// Add all if not exists
  void addAllIfNotExists(Map<K, V> other) {
    other.forEach((key, value) {
      if (!containsKey(key)) {
        this[key] = value;
      }
    });
  }

  /// Filter map
  Map<K, V> filter(bool Function(K key, V value) test) {
    final result = <K, V>{};
    forEach((key, value) {
      if (test(key, value)) {
        result[key] = value;
      }
    });
    return result;
  }
}

/// Nullable Map Extensions
extension NullableMapExtension<K, V> on Map<K, V>? {
  /// Check if map is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Check if map is not null and not empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  /// Return empty map if null
  Map<K, V> get orEmpty => this ?? {};
}
