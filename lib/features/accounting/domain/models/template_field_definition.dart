/// Field type definitions for accounting books
class TemplateFieldDefinition {
  final String fieldCode; // 'stt', 'date', 'revenue', etc.
  final String fieldLabel; // Vietnamese label like 'STT', 'Ngày tháng'
  final String
  fieldType; // 'auto_increment', 'text', 'date', 'decimal', 'formula'
  final String exportColumn; // 'A', 'B', 'C', etc.
  final int sortOrder; // Order in table
  final bool isRequired; // Is required
  final String? formulaExpression; // For formula fields
  final int? maxLength; // For text fields

  const TemplateFieldDefinition({
    required this.fieldCode,
    required this.fieldLabel,
    required this.fieldType,
    required this.exportColumn,
    required this.sortOrder,
    required this.isRequired,
    this.formulaExpression,
    this.maxLength,
  });
}

/// Template definition for each accounting book type
class TemplateDefinition {
  final String templateCode; // 'S1a', 'S2a', 'S2b', 'S2c', 'S2d', 'S2e'
  final String templateName; // Vietnamese name
  final String description;
  final List<TemplateFieldDefinition> fields;

  const TemplateDefinition({
    required this.templateCode,
    required this.templateName,
    required this.description,
    required this.fields,
  });

  /// Get display columns (exclude static/formula only)
  List<TemplateFieldDefinition> get displayColumns =>
      fields.where((f) => f.fieldType != 'formula').toList();

  /// Get formula fields
  List<TemplateFieldDefinition> get formulaFields =>
      fields.where((f) => f.fieldType == 'formula').toList();
}

/// Template registry
class TemplateRegistry {
  static final Map<String, TemplateDefinition> templates = {
    'S1a': _createS1a(),
    'S2a': _createS2a(),
    'S2b': _createS2b(),
    'S2c': _createS2c(),
    'S2d': _createS2d(),
    'S2e': _createS2e(),
    'S3a': _createS3a(),
  };

  static TemplateDefinition? getTemplate(String templateCode) {
    final normalized = templateCode.trim().toLowerCase();
    for (final entry in templates.entries) {
      if (entry.key.toLowerCase() == normalized) {
        return entry.value;
      }
    }
    return null;
  }

  // ═══ S1a — Sổ chi tiết bán hàng ═══
  static TemplateDefinition _createS1a() => TemplateDefinition(
    templateCode: 'S1a',
    templateName: 'Sổ chi tiết bán hàng',
    description:
        'Sổ chi tiết bán hàng cho Nhóm 1 (DT < 500 triệu/năm) — miễn thuế',
    fields: [
      TemplateFieldDefinition(
        fieldCode: 'stt',
        fieldLabel: 'STT',
        fieldType: 'auto_increment',
        exportColumn: 'A',
        sortOrder: 1,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'date',
        fieldLabel: 'Ngày tháng',
        fieldType: 'date',
        exportColumn: 'B',
        sortOrder: 2,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'description',
        fieldLabel: 'Nội dung',
        fieldType: 'text',
        exportColumn: 'C',
        sortOrder: 3,
        isRequired: true,
        maxLength: 200,
      ),
      TemplateFieldDefinition(
        fieldCode: 'revenue',
        fieldLabel: 'Doanh thu bán hàng',
        fieldType: 'decimal',
        exportColumn: 'D',
        sortOrder: 4,
        isRequired: true,
      ),
    ],
  );

  // ═══ S2a — Sổ doanh thu Cách 1 ═══
  static TemplateDefinition _createS2a() => TemplateDefinition(
    templateCode: 'S2a',
    templateName: 'Sổ doanh thu bán hàng hóa, dịch vụ (Cách 1)',
    description:
        'Sổ doanh thu theo ngành — tính thuế GTGT + TNCN trực tiếp trên DT. Áp dụng Nhóm 2 Cách 1.',
    fields: [
      TemplateFieldDefinition(
        fieldCode: 'stt',
        fieldLabel: 'STT',
        fieldType: 'auto_increment',
        exportColumn: 'A',
        sortOrder: 1,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'so_hieu',
        fieldLabel: 'Chứng từ - Số hiệu',
        fieldType: 'text',
        exportColumn: 'B',
        sortOrder: 2,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'ngay_thang',
        fieldLabel: 'Chứng từ - Ngày tháng',
        fieldType: 'date',
        exportColumn: 'C',
        sortOrder: 3,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'dien_giai',
        fieldLabel: 'Diễn giải',
        fieldType: 'text',
        exportColumn: 'D',
        sortOrder: 4,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'so_tien',
        fieldLabel: 'Số tiền (1)',
        fieldType: 'decimal',
        exportColumn: 'E',
        sortOrder: 5,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'cong_quy',
        fieldLabel: 'Cộng quý',
        fieldType: 'formula',
        exportColumn: 'E',
        sortOrder: 10,
        isRequired: true,
        formulaExpression: 'SUM(so_tien)',
      ),
      TemplateFieldDefinition(
        fieldCode: 'thue_gtgt',
        fieldLabel: 'Thuế GTGT phải nộp',
        fieldType: 'formula',
        exportColumn: 'E',
        sortOrder: 11,
        isRequired: true,
        formulaExpression: 'cong_quy * VAT_RATE',
      ),
      TemplateFieldDefinition(
        fieldCode: 'thue_tncn',
        fieldLabel: 'Thuế TNCN phải nộp',
        fieldType: 'formula',
        exportColumn: 'E',
        sortOrder: 12,
        isRequired: true,
        formulaExpression: 'MAX(0, TOTAL_REVENUE - 500M) * PIT_RATE',
      ),
    ],
  );

  // ═══ S2b — Sổ doanh thu Cách 2 ═══
  static TemplateDefinition _createS2b() => TemplateDefinition(
    templateCode: 'S2b',
    templateName: 'Sổ doanh thu bán hàng hóa, dịch vụ (Cách 2)',
    description:
        'Sổ doanh thu theo ngành — chỉ tính thuế GTGT (TNCN tính ở S2c). Áp dụng Nhóm 2 Cách 2, Nhóm 3-4.',
    fields: [
      TemplateFieldDefinition(
        fieldCode: 'stt',
        fieldLabel: 'STT',
        fieldType: 'auto_increment',
        exportColumn: 'A',
        sortOrder: 1,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'so_hieu',
        fieldLabel: 'Chứng từ - Số hiệu',
        fieldType: 'text',
        exportColumn: 'B',
        sortOrder: 2,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'ngay_thang',
        fieldLabel: 'Chứng từ - Ngày tháng',
        fieldType: 'date',
        exportColumn: 'C',
        sortOrder: 3,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'dien_giai',
        fieldLabel: 'Diễn giải',
        fieldType: 'text',
        exportColumn: 'D',
        sortOrder: 4,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'so_tien',
        fieldLabel: 'Số tiền (1)',
        fieldType: 'decimal',
        exportColumn: 'E',
        sortOrder: 5,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'cong_quy',
        fieldLabel: 'Cộng quý',
        fieldType: 'formula',
        exportColumn: 'E',
        sortOrder: 10,
        isRequired: true,
        formulaExpression: 'SUM(so_tien)',
      ),
      TemplateFieldDefinition(
        fieldCode: 'thue_gtgt',
        fieldLabel: 'Thuế GTGT phải nộp',
        fieldType: 'formula',
        exportColumn: 'E',
        sortOrder: 11,
        isRequired: true,
        formulaExpression: 'cong_quy * VAT_RATE',
      ),
    ],
  );

  // ═══ S2c — Sổ chi tiết DT, CP ═══
  static TemplateDefinition _createS2c() => TemplateDefinition(
    templateCode: 'S2c',
    templateName: 'Sổ chi tiết doanh thu, chi phí',
    description:
        'Ghi doanh thu và chi phí hợp lý, tính chênh lệch = thu nhập chịu thuế TNCN. Áp dụng Nhóm 2 Cách 2, Nhóm 3-4.',
    fields: [
      TemplateFieldDefinition(
        fieldCode: 'stt',
        fieldLabel: 'STT',
        fieldType: 'auto_increment',
        exportColumn: 'A',
        sortOrder: 1,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'so_hieu',
        fieldLabel: 'Chứng từ - Số hiệu',
        fieldType: 'text',
        exportColumn: 'B',
        sortOrder: 2,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'ngay_thang',
        fieldLabel: 'Chứng từ - Ngày tháng',
        fieldType: 'date',
        exportColumn: 'C',
        sortOrder: 3,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'dien_giai',
        fieldLabel: 'Diễn giải',
        fieldType: 'text',
        exportColumn: 'D',
        sortOrder: 4,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'so_tien',
        fieldLabel: 'Số tiền (1)',
        fieldType: 'decimal',
        exportColumn: 'E',
        sortOrder: 5,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'section',
        fieldLabel: 'Phần',
        fieldType: 'text',
        exportColumn: 'F',
        sortOrder: 6,
        isRequired: false,
      ),
      TemplateFieldDefinition(
        fieldCode: 'tong_dt',
        fieldLabel: 'Tổng doanh thu',
        fieldType: 'formula',
        exportColumn: 'E',
        sortOrder: 10,
        isRequired: true,
        formulaExpression: 'SUM(so_tien WHERE section=revenue)',
      ),
      TemplateFieldDefinition(
        fieldCode: 'tong_cp',
        fieldLabel: 'Tổng chi phí hợp lý',
        fieldType: 'formula',
        exportColumn: 'E',
        sortOrder: 11,
        isRequired: true,
        formulaExpression: 'SUM(so_tien WHERE section=cost)',
      ),
      TemplateFieldDefinition(
        fieldCode: 'chenh_lech',
        fieldLabel: 'Chênh lệch (DT - CP)',
        fieldType: 'formula',
        exportColumn: 'E',
        sortOrder: 12,
        isRequired: true,
        formulaExpression: 'tong_dt - tong_cp',
      ),
      TemplateFieldDefinition(
        fieldCode: 'thue_tncn',
        fieldLabel: 'Thuế TNCN phải nộp',
        fieldType: 'formula',
        exportColumn: 'E',
        sortOrder: 13,
        isRequired: true,
        formulaExpression: 'MAX(0, chenh_lech) * PIT_RATE',
      ),
    ],
  );

  // ═══ S2d — Sổ kho XNT ═══
  static TemplateDefinition _createS2d() => TemplateDefinition(
    templateCode: 'S2d',
    templateName: 'Sổ chi tiết vật liệu, dụng cụ, sản phẩm, hàng hóa',
    description:
        'Sổ kho XNT — nhập/xuất/tồn, bình quân gia quyền. Mỗi sản phẩm 1 trang. Áp dụng Nhóm 2 Cách 2, Nhóm 3-4.',
    fields: [
      TemplateFieldDefinition(
        fieldCode: 'so_hieu',
        fieldLabel: 'Chứng từ - Số hiệu',
        fieldType: 'text',
        exportColumn: 'A',
        sortOrder: 1,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'ngay',
        fieldLabel: 'Chứng từ - Ngày',
        fieldType: 'date',
        exportColumn: 'B',
        sortOrder: 2,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'dien_giai',
        fieldLabel: 'Diễn giải',
        fieldType: 'text',
        exportColumn: 'C',
        sortOrder: 3,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'dvt',
        fieldLabel: 'ĐVT',
        fieldType: 'text',
        exportColumn: 'D',
        sortOrder: 4,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'don_gia',
        fieldLabel: 'Đơn giá (1)',
        fieldType: 'decimal',
        exportColumn: 'E',
        sortOrder: 5,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'sl_nhap',
        fieldLabel: 'Nhập - SL (2)',
        fieldType: 'decimal',
        exportColumn: 'F',
        sortOrder: 6,
        isRequired: false,
      ),
      TemplateFieldDefinition(
        fieldCode: 'tien_nhap',
        fieldLabel: 'Nhập - Tiền (3)',
        fieldType: 'decimal',
        exportColumn: 'G',
        sortOrder: 7,
        isRequired: false,
      ),
      TemplateFieldDefinition(
        fieldCode: 'sl_xuat',
        fieldLabel: 'Xuất - SL (4)',
        fieldType: 'decimal',
        exportColumn: 'H',
        sortOrder: 8,
        isRequired: false,
      ),
      TemplateFieldDefinition(
        fieldCode: 'tien_xuat',
        fieldLabel: 'Xuất - Tiền (5)',
        fieldType: 'decimal',
        exportColumn: 'I',
        sortOrder: 9,
        isRequired: false,
      ),
      TemplateFieldDefinition(
        fieldCode: 'sl_ton',
        fieldLabel: 'Tồn - SL (6)',
        fieldType: 'decimal',
        exportColumn: 'J',
        sortOrder: 10,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'tien_ton',
        fieldLabel: 'Tồn - Tiền (7)',
        fieldType: 'decimal',
        exportColumn: 'K',
        sortOrder: 11,
        isRequired: true,
      ),
    ],
  );

  // ═══ S2e — Sổ chi tiết tiền ═══
  static TemplateDefinition _createS2e() => TemplateDefinition(
    templateCode: 'S2e',
    templateName: 'Sổ chi tiết tiền',
    description:
        'Theo dõi tiền mặt + tiền gửi không kỳ hạn: thu/chi, gửi/rút, tồn quỹ. Áp dụng Nhóm 2 Cách 2, Nhóm 3-4.',
    fields: [
      TemplateFieldDefinition(
        fieldCode: 'stt',
        fieldLabel: 'STT',
        fieldType: 'auto_increment',
        exportColumn: 'A',
        sortOrder: 1,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'so_hieu',
        fieldLabel: 'Chứng từ - Số hiệu',
        fieldType: 'text',
        exportColumn: 'B',
        sortOrder: 2,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'ngay_thang',
        fieldLabel: 'Chứng từ - Ngày tháng',
        fieldType: 'date',
        exportColumn: 'C',
        sortOrder: 3,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'dien_giai',
        fieldLabel: 'Diễn giải',
        fieldType: 'text',
        exportColumn: 'D',
        sortOrder: 4,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'thu_vao',
        fieldLabel: 'Thu/Gửi vào (1)',
        fieldType: 'decimal',
        exportColumn: 'E',
        sortOrder: 5,
        isRequired: false,
      ),
      TemplateFieldDefinition(
        fieldCode: 'chi_ra',
        fieldLabel: 'Chi/Rút ra (2)',
        fieldType: 'decimal',
        exportColumn: 'F',
        sortOrder: 6,
        isRequired: false,
      ),
      TemplateFieldDefinition(
        fieldCode: 'section',
        fieldLabel: 'Phần (cash|bank)',
        fieldType: 'text',
        exportColumn: 'G',
        sortOrder: 7,
        isRequired: false,
      ),
    ],
  );

  // ═══ S3a — Sổ tài sản cố định ═══
  static TemplateDefinition _createS3a() => TemplateDefinition(
    templateCode: 'S3a',
    templateName: 'Sổ tài sản cố định',
    description:
        'Theo dõi tăng, giảm và giá trị còn lại của tài sản cố định theo kỳ.',
    fields: [
      TemplateFieldDefinition(
        fieldCode: 'stt',
        fieldLabel: 'STT',
        fieldType: 'auto_increment',
        exportColumn: 'A',
        sortOrder: 1,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'asset_name',
        fieldLabel: 'Tên tài sản',
        fieldType: 'text',
        exportColumn: 'B',
        sortOrder: 2,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'voucher_no',
        fieldLabel: 'Số chứng từ',
        fieldType: 'text',
        exportColumn: 'C',
        sortOrder: 3,
        isRequired: false,
      ),
      TemplateFieldDefinition(
        fieldCode: 'recorded_date',
        fieldLabel: 'Ngày ghi nhận',
        fieldType: 'date',
        exportColumn: 'D',
        sortOrder: 4,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'increase_amount',
        fieldLabel: 'Giá trị tăng',
        fieldType: 'decimal',
        exportColumn: 'E',
        sortOrder: 5,
        isRequired: false,
      ),
      TemplateFieldDefinition(
        fieldCode: 'decrease_amount',
        fieldLabel: 'Giá trị giảm',
        fieldType: 'decimal',
        exportColumn: 'F',
        sortOrder: 6,
        isRequired: false,
      ),
      TemplateFieldDefinition(
        fieldCode: 'remaining_amount',
        fieldLabel: 'Giá trị còn lại',
        fieldType: 'decimal',
        exportColumn: 'G',
        sortOrder: 7,
        isRequired: true,
      ),
      TemplateFieldDefinition(
        fieldCode: 'note',
        fieldLabel: 'Ghi chú',
        fieldType: 'text',
        exportColumn: 'H',
        sortOrder: 8,
        isRequired: false,
      ),
    ],
  );
}
