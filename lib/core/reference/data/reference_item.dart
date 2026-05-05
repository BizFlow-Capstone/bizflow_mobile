/// Represents a reference data item returned by the /api/reference/* endpoints.
/// The API returns objects in the shape { code: "...", label: "..." }.
class ReferenceItem {
  final String code;
  final String label;

  const ReferenceItem({required this.code, required this.label});

  /// Parse from a JSON map returned by the API.
  factory ReferenceItem.fromJson(Map<String, dynamic> json) {
    return ReferenceItem(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }

  /// Safely parse from any dynamic value (Map or plain String fallback).
  factory ReferenceItem.fromDynamic(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return ReferenceItem.fromJson(raw);
    }
    final str = raw?.toString() ?? '';
    return ReferenceItem(code: str, label: str);
  }

  Map<String, dynamic> toJson() => {'code': code, 'label': label};

  @override
  bool operator ==(Object other) =>
      other is ReferenceItem && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => label;
}

String referenceCodeFromDynamic(dynamic raw, {String fallback = ''}) {
  if (raw == null) return fallback;
  if (raw is ReferenceItem) return raw.code;
  if (raw is Map<String, dynamic>) {
    final code =
        raw['code']?.toString().trim() ??
        raw['Code']?.toString().trim() ??
        '';
    return code.isNotEmpty ? code : fallback;
  }
  if (raw is Map) {
    final code =
        raw['code']?.toString().trim() ??
        raw['Code']?.toString().trim() ??
        '';
    return code.isNotEmpty ? code : fallback;
  }
  final text = raw.toString().trim();
  return text.isNotEmpty ? text : fallback;
}

String? referenceLabelFromDynamic(dynamic raw) {
  if (raw == null) return null;
  if (raw is ReferenceItem) {
    final label = raw.label.trim();
    return label.isEmpty ? null : label;
  }
  if (raw is Map<String, dynamic>) {
    final label =
        raw['label']?.toString().trim() ??
        raw['Label']?.toString().trim() ??
        '';
    return label.isEmpty ? null : label;
  }
  if (raw is Map) {
    final label =
        raw['label']?.toString().trim() ??
        raw['Label']?.toString().trim() ??
        '';
    return label.isEmpty ? null : label;
  }
  return null;
}

/// Extension to find label by code from a list of ReferenceItems.
extension ReferenceItemListExt on List<ReferenceItem> {
  /// Get the label for a given code. If not found, returns the code itself.
  String getLabelByCode(String code) {
    try {
      final item = firstWhere((item) => item.code == code);
      return item.label.trim().isNotEmpty ? item.label : code;
    } catch (_) {
      return code;
    }
  }
}
