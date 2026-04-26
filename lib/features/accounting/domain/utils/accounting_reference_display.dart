 class AccountingReferenceDisplay {
  const AccountingReferenceDisplay._();

  static const List<String> _typeKeys = <String>[
    'referenceType',
    'ReferenceType',
    'entityType',
    'EntityType',
    'refType',
  ];

  static const List<String> _idKeys = <String>[
    'referenceId',
    'ReferenceId',
    'entityId',
    'EntityId',
    'refId',
    'orderId',
    'OrderId',
    'importId',
    'ImportId',
    'revenueId',
    'RevenueId',
    'costId',
    'CostId',
  ];

  static const List<String> _documentKeys = <String>[
    'so_hieu',
    'documentNumber',
    'DocumentNumber',
    'voucherNo',
    'voucher_no',
    'so_chung_tu',
    'documentNo',
    'DocumentNo',
  ];

  static const List<String> _referenceCodeKeys = <String>[
    'referenceCode',
    'ReferenceCode',
    'code',
    'bookCode',
    'orderCode',
    'importCode',
  ];

  static const List<String> _descriptionKeys = <String>[
    'dien_giai',
    'description',
    'Description',
    'note',
    'remark',
    'content',
  ];

  static List<Map<String, dynamic>> normalizeRows(
    List<Map<String, dynamic>> rows, {
    String languageCode = 'vi',
  }) {
    return rows
        .map(
          (row) => normalizeRow(row, languageCode: languageCode),
        )
        .toList(growable: false);
  }

  static Map<String, dynamic> normalizeRow(
    Map<String, dynamic> row, {
    String languageCode = 'vi',
  }) {
    final normalized = Map<String, dynamic>.from(row);

    final referenceType = _firstText(row, _typeKeys);
    final referenceId = _firstValue(row, _idKeys);
    final referenceCode = _firstText(row, _referenceCodeKeys);

    final rawCode = _firstText(normalized, _documentKeys);
    final rawDescription = _firstText(normalized, _descriptionKeys);

    final displayCode = displayDocument(
      documentNumber: rawCode,
      referenceType: referenceType,
      referenceId: referenceId,
      referenceCode: referenceCode,
      languageCode: languageCode,
    );
    normalized['so_hieu'] = displayCode;

    final displayDescription = displayDescriptionValue(
      description: rawDescription,
      referenceType: referenceType,
      referenceId: referenceId,
      referenceCode: referenceCode ?? rawCode,
      languageCode: languageCode,
    );
    if (displayDescription.isNotEmpty) {
      normalized['dien_giai'] = displayDescription;
      normalized['description'] = displayDescription;

      final note = (normalized['note'] ?? '').toString().trim();
      if (_shouldReplaceText(note)) {
        normalized['note'] = displayDescription;
      }
    }

    return normalized;
  }

  static String displayReference({
    String? referenceType,
    dynamic referenceId,
    String? referenceCode,
    String languageCode = 'vi',
    String fallback = '',
  }) {
    final lang = _normalizeLanguage(languageCode);
    final resolved = _resolveReference(
      referenceType: referenceType,
      referenceId: referenceId,
      referenceCode: referenceCode,
    );

    if (resolved != null) {
      return '${_typeLabel(resolved.type, lang)} ${resolved.id}'.trim();
    }

    final fromCode = _humanizeToken(referenceCode, languageCode: lang);
    if (fromCode != null && fromCode.isNotEmpty) {
      return fromCode;
    }

    return fallback;
  }

  static String displayDocument({
    required String? documentNumber,
    String? referenceType,
    dynamic referenceId,
    String? referenceCode,
    String languageCode = 'vi',
  }) {
    final raw = (documentNumber ?? '').trim();

    if (raw.isEmpty) {
      return '';
    }
    // Keep user-entered document numbers as-is (e.g. ORD-123456).
    // Humanized labels are only used when documentNumber is missing.
    return raw;
  }

  static String displayDescriptionValue({
    required String? description,
    String? referenceType,
    dynamic referenceId,
    String? referenceCode,
    String languageCode = 'vi',
  }) {
    final raw = (description ?? '').trim();
    final lang = _normalizeLanguage(languageCode);
    final label = displayReference(
      referenceType: referenceType,
      referenceId: referenceId,
      referenceCode: referenceCode,
      languageCode: lang,
    );

    if (raw.isEmpty || raw == '-') {
      return label;
    }

    if (_isSummaryLabel(raw)) {
      return raw;
    }

    final tokenLabel = _humanizeToken(
      raw,
      referenceType: referenceType,
      referenceId: referenceId,
      languageCode: lang,
    );
    if (tokenLabel != null && tokenLabel.isNotEmpty) {
      return tokenLabel;
    }

    if (_isNumeric(raw)) {
      final type = _normalizeType(referenceType) ??
          _resolveReference(
            referenceType: referenceType,
            referenceId: referenceId,
            referenceCode: referenceCode,
          )
              ?.type;
      if (type != null) {
        return '${_typeLabel(type, lang)} $raw';
      }
      if (label.isNotEmpty) {
        return label;
      }
    }

    if (referenceCode != null &&
        referenceCode.trim().isNotEmpty &&
        _normalizeLoose(raw) == _normalizeLoose(referenceCode) &&
        label.isNotEmpty) {
      return label;
    }

    return raw;
  }

  static bool _shouldReplaceText(String value) {
    if (value.isEmpty) return true;
    if (value == '-') return true;
    if (_isNumeric(value)) return true;
    if (_looksLikeReferenceToken(value)) return true;
    return false;
  }

  static bool _isSummaryLabel(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    return normalized.contains('tổng') ||
        normalized.contains('tong') ||
        normalized.contains('thuế') ||
        normalized.contains('thue') ||
        normalized.contains('chênh lệch') ||
        normalized.contains('chenh lech');
  }

  static String _normalizeLanguage(String languageCode) {
    final lower = languageCode.toLowerCase();
    return lower.startsWith('en') ? 'en' : 'vi';
  }

  static String _typeLabel(String type, String languageCode) {
    switch (type) {
      case 'order':
        return languageCode == 'en' ? 'Order' : 'Đơn hàng';
      case 'revenue':
        return languageCode == 'en' ? 'Revenue' : 'Doanh thu';
      case 'cost':
        return languageCode == 'en' ? 'Cost' : 'Chi phí';
      case 'import':
        return languageCode == 'en' ? 'Import receipt' : 'Phiếu nhập';
      case 'manual':
        return languageCode == 'en' ? 'Manual entry' : 'Thủ công';
      case 'payment':
        return languageCode == 'en' ? 'Payment' : 'Thanh toán';
      case 'tax':
        return languageCode == 'en' ? 'Tax' : 'Thuế';
      default:
        return languageCode == 'en' ? 'Reference' : 'Chứng từ';
    }
  }

  static _ResolvedReference? _resolveReference({
    String? referenceType,
    dynamic referenceId,
    String? referenceCode,
  }) {
    final type = _normalizeType(referenceType);
    final id = _normalizeId(referenceId);
    final parsedCode = _parseReferenceToken(referenceCode);

    if (type != null && id != null) {
      return _ResolvedReference(type: type, id: id);
    }
    if (type != null && parsedCode != null) {
      return _ResolvedReference(type: type, id: parsedCode.id);
    }
    if (id != null && parsedCode != null) {
      return _ResolvedReference(type: parsedCode.type, id: id);
    }
    return parsedCode;
  }

  static _ResolvedReference? _parseReferenceToken(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;

    final compact = raw.replaceAll(' ', '');

    final separated = RegExp(r'^([A-Za-z_]+)[\-_/:#]+([0-9]{1,18})$');
    final separatedMatch = separated.firstMatch(compact);
    if (separatedMatch != null) {
      final type = _normalizeType(separatedMatch.group(1));
      final id = separatedMatch.group(2);
      if (type != null && id != null) {
        return _ResolvedReference(type: type, id: id);
      }
    }

    final attached = RegExp(r'^([A-Za-z_]{2,})([0-9]{1,18})$');
    final attachedMatch = attached.firstMatch(compact);
    if (attachedMatch != null) {
      final type = _normalizeType(attachedMatch.group(1));
      final id = attachedMatch.group(2);
      if (type != null && id != null) {
        return _ResolvedReference(type: type, id: id);
      }
    }

    return null;
  }

  static String? _normalizeType(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    if (raw.isEmpty) return null;

    final compact = raw.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (compact.isEmpty) return null;

    if (compact.contains('order') || compact.startsWith('ord')) {
      return 'order';
    }
    if (compact.contains('revenue') ||
        compact.startsWith('rev') ||
        compact.contains('doanhthu')) {
      return 'revenue';
    }
    if (compact.contains('cost') ||
        compact.contains('expense') ||
        compact.contains('chiphi')) {
      return 'cost';
    }
    if (compact.contains('inventory') ||
        compact.contains('import') ||
        compact.startsWith('imp') ||
        compact.contains('phieunhap')) {
      return 'import';
    }
    if (compact.contains('manual') || compact.contains('thucong')) {
      return 'manual';
    }
    if (compact.contains('payment') || compact.contains('thanhtoan')) {
      return 'payment';
    }
    if (compact.contains('tax') || compact.contains('thue')) {
      return 'tax';
    }

    return compact;
  }

  static String? _normalizeId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value.toString();
    if (value is num) return value.toInt().toString();

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    if (_isNumeric(text)) {
      return text;
    }

    final parsed = _parseReferenceToken(text);
    if (parsed != null) {
      return parsed.id;
    }

    return null;
  }

  static bool _isNumeric(String value) {
    return RegExp(r'^\d+$').hasMatch(value.trim());
  }

  static bool _looksLikeReferenceToken(String value) {
    return _parseReferenceToken(value) != null;
  }

  static String _normalizeLoose(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String? _humanizeToken(
    String? value, {
    String? referenceType,
    dynamic referenceId,
    required String languageCode,
  }) {
    final token = (value ?? '').trim();
    if (token.isEmpty) return null;

    final parsed = _parseReferenceToken(token);
    if (parsed != null) {
      return '${_typeLabel(parsed.type, languageCode)} ${parsed.id}'.trim();
    }

    if (_isNumeric(token)) {
      final type = _normalizeType(referenceType);
      if (type == null) return null;

      final explicitId = _normalizeId(referenceId);
      final resolvedId = explicitId ?? token;
      return '${_typeLabel(type, languageCode)} $resolvedId'.trim();
    }

    return null;
  }

  static String? _firstText(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static dynamic _firstValue(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      if (!source.containsKey(key)) continue;
      final value = source[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return value;
    }
    return null;
  }
}

class _ResolvedReference {
  final String type;
  final String id;

  const _ResolvedReference({
    required this.type,
    required this.id,
  });
}