import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../../domain/models/accounting_book.dart';
import 's1a_export_service.dart';
import 's2a_export_service.dart';
import 's2b_export_service.dart';
import 's2c_export_service.dart';
import 's2d_export_service.dart';
import 's2e_export_service.dart';
import 's3a_export_service.dart';

class ExcelExportHeaderInfo {
  final String businessName;
  final String taxCode;
  final String address;
  final String locationName;
  final String periodLabel;

  const ExcelExportHeaderInfo({
    this.businessName = '',
    this.taxCode = '',
    this.address = '',
    this.locationName = '',
    this.periodLabel = '',
  });
}

class ExcelExportService {
  static bool _isS2dTemplate(String templateCode) {
    return templateCode.trim().toLowerCase() == 's2d';
  }

  static bool _isS1aTemplate(String templateCode) {
    return templateCode.trim().toLowerCase() == 's1a';
  }

  static bool _isS2aTemplate(String templateCode) {
    return templateCode.trim().toLowerCase() == 's2a';
  }

  static bool _isS2bTemplate(String templateCode) {
    return templateCode.trim().toLowerCase() == 's2b';
  }

  static bool _isS2cTemplate(String templateCode) {
    return templateCode.trim().toLowerCase() == 's2c';
  }

  static bool _isS2eTemplate(String templateCode) {
    return templateCode.trim().toLowerCase() == 's2e';
  }

  static bool _isS3aTemplate(String templateCode) {
    return templateCode.trim().toLowerCase() == 's3a';
  }

  static const Map<String, String> _s2dCategoryDisplay = {
    'MATERIAL': 'VatLieu',
    'TOOL': 'DungCu',
    'PRODUCT': 'SanPham',
    'GOODS': 'HangHoa',
    'OTHER': 'Khac',
  };

  static String _normalizeS2dCategory(dynamic raw) {
    final text = (raw ?? '').toString().trim().toUpperCase();
    if (text.isEmpty) return 'OTHER';

    if (text.contains('VAT_LIEU') ||
        text.contains('VẬT LIỆU') ||
        text.contains('MATERIAL')) {
      return 'MATERIAL';
    }
    if (text.contains('DUNG_CU') ||
        text.contains('DỤNG CỤ') ||
        text.contains('TOOL')) {
      return 'TOOL';
    }
    if (text.contains('SAN_PHAM') ||
        text.contains('SẢN PHẨM') ||
        text.contains('PRODUCT')) {
      return 'PRODUCT';
    }
    if (text.contains('HANG_HOA') ||
        text.contains('HÀNG HÓA') ||
        text.contains('GOODS')) {
      return 'GOODS';
    }
    return 'OTHER';
  }

  static dynamic _extractS2dCategory(Map<String, dynamic> row) {
    const keys = [
      'category',
      'itemCategory',
      'productCategory',
      'inventoryCategory',
      'itemType',
      'section',
      'kind',
      'type',
    ];
    for (final key in keys) {
      if (row.containsKey(key) && row[key] != null) {
        return row[key];
      }
    }
    return null;
  }

  /// Export [book] data to one or more Excel files.
  ///
  /// This service only dispatches to dedicated template exporters.
  static Future<List<File>> exportToExcelFiles(
    AccountingBook book,
    List<Map<String, dynamic>> rows, {
    BookSectionsResponse? sectionsData,
    ExcelExportHeaderInfo? headerInfo,
  }) async {
    if (_isS1aTemplate(book.templateCode)) {
      final file = await S1aExportService.export(
        book: book,
        dataRows: rows,
        sectionsData: sectionsData,
        businessName: headerInfo?.businessName ?? '',
        taxCode: headerInfo?.taxCode ?? '',
        address: headerInfo?.address ?? '',
        locationName: headerInfo?.locationName ?? '',
        periodLabel: headerInfo?.periodLabel ?? '',
      );
      if (file != null) return <File>[file];
      throw Exception('Không thể xuất S1a. Vui lòng kiểm tra dữ liệu sổ và thử lại.');
    }

    if (_isS2aTemplate(book.templateCode) && sectionsData != null) {
      final file = await S2aExportService.export(
        book: book,
        dataRows: rows,
        sectionsData: sectionsData,
        businessName: headerInfo?.businessName ?? '',
        taxCode: headerInfo?.taxCode ?? '',
        address: headerInfo?.address ?? '',
        locationName: headerInfo?.locationName ?? '',
        periodLabel: headerInfo?.periodLabel ?? '',
      );
      if (file != null) return <File>[file];
      throw Exception('Không thể xuất S2a theo mẫu template.');
    }

    if (_isS2dTemplate(book.templateCode)) {
      if (sectionsData != null && sectionsData.sections.isNotEmpty) {
        final files = <File>[];
        for (final section in sectionsData.sections) {
          final sectionRows = section.rows
              .where((r) => r.lineType == 'data')
              .map((r) => r.values)
              .toList();
          if (sectionRows.isEmpty) continue;

          final suffix = section.businessTypeName?.trim().isNotEmpty == true
              ? section.businessTypeName!.trim()
              : 'Loai_${section.groupIndex}';

          final file = await S2dExportService.export(
            book: book,
            dataRows: sectionRows,
            categoryName: suffix,
            sectionsData: sectionsData,
            businessName: headerInfo?.businessName ?? '',
            taxCode: headerInfo?.taxCode ?? '',
            address: headerInfo?.address ?? '',
            locationName: headerInfo?.locationName ?? '',
            periodLabel: headerInfo?.periodLabel ?? '',
          );
          if (file != null) files.add(file);
        }
        return files;
      }

      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final row in rows) {
        final category = _normalizeS2dCategory(_extractS2dCategory(row));
        grouped.putIfAbsent(category, () => <Map<String, dynamic>>[]).add(row);
      }

      final files = <File>[];
      for (final entry in grouped.entries) {
        if (entry.value.isEmpty) continue;
        final display = _s2dCategoryDisplay[entry.key] ?? entry.key;
        final file = await S2dExportService.export(
          book: book,
          dataRows: entry.value,
          categoryName: display,
          sectionsData: sectionsData,
          businessName: headerInfo?.businessName ?? '',
          taxCode: headerInfo?.taxCode ?? '',
          address: headerInfo?.address ?? '',
          locationName: headerInfo?.locationName ?? '',
          periodLabel: headerInfo?.periodLabel ?? '',
        );
        if (file != null) files.add(file);
      }
      return files;
    }

    if (_isS2bTemplate(book.templateCode)) {
      final file = await S2bExportService.export(
        book: book,
        dataRows: rows,
        sectionsData: sectionsData,
        businessName: headerInfo?.businessName ?? '',
        taxCode: headerInfo?.taxCode ?? '',
        address: headerInfo?.address ?? '',
        locationName: headerInfo?.locationName ?? '',
        periodLabel: headerInfo?.periodLabel ?? '',
      );
      if (file != null) return <File>[file];
      throw Exception('Không thể xuất S2b theo mẫu template.');
    }

    if (_isS2cTemplate(book.templateCode)) {
      final file = await S2cExportService.export(
        book: book,
        dataRows: rows,
        sectionsData: sectionsData,
        businessName: headerInfo?.businessName ?? '',
        taxCode: headerInfo?.taxCode ?? '',
        address: headerInfo?.address ?? '',
        locationName: headerInfo?.locationName ?? '',
        periodLabel: headerInfo?.periodLabel ?? '',
      );
      if (file != null) return <File>[file];
      throw Exception('Không thể xuất S2c theo mẫu template.');
    }

    if (_isS2eTemplate(book.templateCode)) {
      final file = await S2eExportService.export(
        book: book,
        dataRows: rows,
        sectionsData: sectionsData,
        businessName: headerInfo?.businessName ?? '',
        taxCode: headerInfo?.taxCode ?? '',
        address: headerInfo?.address ?? '',
        locationName: headerInfo?.locationName ?? '',
        periodLabel: headerInfo?.periodLabel ?? '',
      );
      if (file != null) return <File>[file];
      throw Exception('Không thể xuất S2e theo mẫu template.');
    }

    if (_isS3aTemplate(book.templateCode)) {
      final file = await S3aExportService.export(
        book: book,
        dataRows: rows,
        sectionsData: sectionsData,
        businessName: headerInfo?.businessName ?? '',
        taxCode: headerInfo?.taxCode ?? '',
        address: headerInfo?.address ?? '',
        locationName: headerInfo?.locationName ?? '',
        periodLabel: headerInfo?.periodLabel ?? '',
      );
      if (file != null) return <File>[file];
      throw Exception('Không thể xuất S3a theo mẫu template.');
    }

    throw Exception('Mẫu sổ chưa hỗ trợ xuất file bằng Syncfusion.');
  }

  static Future<File?> exportToExcel(
    AccountingBook book,
    List<Map<String, dynamic>> rows, {
    BookSectionsResponse? sectionsData,
    ExcelExportHeaderInfo? headerInfo,
  }) async {
    try {
      final files = await exportToExcelFiles(
        book,
        rows,
        sectionsData: sectionsData,
        headerInfo: headerInfo,
      );
      return files.isNotEmpty ? files.first : null;
    } catch (e) {
      // ignore: avoid_print
      print('Error exporting to Excel: $e');
      return null;
    }
  }

  static Future<void> shareExportedFile(File file) async {
    await shareExportedFiles(<File>[file]);
  }

  static Future<void> shareExportedFiles(List<File> files) async {
    if (files.isEmpty) return;
    try {
      final attachments = files
          .map(
            (file) => XFile(
              file.absolute.path,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          )
          .toList();
      await Share.shareXFiles(attachments, text: 'Sổ kế toán xuất ra Excel');
    } catch (e) {
      // ignore: avoid_print
      print('Error sharing Excel file: $e');
    }
  }

  static Future<List<File>> saveExportedFilesToDownloads(List<File> files) async {
    if (files.isEmpty) return const <File>[];
    if (!Platform.isAndroid) return files;

    final downloadDir = Directory('/storage/emulated/0/Download');
    if (!await downloadDir.exists()) {
      return files;
    }

    final savedFiles = <File>[];
    for (final file in files) {
      final destination = await _createUniqueFile(
        downloadDir,
        file.path.split('/').last,
      );
      savedFiles.add(await file.copy(destination.path));
    }
    return savedFiles;
  }

  static Future<File> _createUniqueFile(
    Directory directory,
    String fileName,
  ) async {
    final dotIndex = fileName.lastIndexOf('.');
    final name = dotIndex >= 0 ? fileName.substring(0, dotIndex) : fileName;
    final extension = dotIndex >= 0 ? fileName.substring(dotIndex) : '';

    var candidate = File('${directory.path}/$fileName');
    var counter = 1;
    while (await candidate.exists()) {
      candidate = File('${directory.path}/$name ($counter)$extension');
      counter++;
    }
    return candidate;
  }
}
