import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/models/accounting_book.dart';
import '../../domain/models/template_field_definition.dart';
import 'package:docx_template/docx_template.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/formatters.dart';

/// Service to export accounting book data to Word document using DOCX format
class WordExportService {
  static const _templateDir =
      'assets/Mẫu sổ sách kế toán HKD theo Thông tư số 152-2025-TT-BTC';

  // Map template code to docx filename
  static final _templateFiles = {
    'S1a': 'Mẫu số S1a-HKD.docx',
    'S2a': 'Mẫu số S2a-HKD.docx',
    'S2b': 'Mẫu số S2b-HKD.docx',
    'S2c': 'Mẫu số S2c-HKD.docx',
    'S2d': 'Mẫu số S2d-HKD.docx',
    'S2e': 'Mẫu số S2e-HKD.docx',
    'S3a': 'Mẫu số S3a-HKD.docx',
  };

  /// Export book data to Word and save to file
  static Future<File?> exportToWord(
    AccountingBook book,
    List<Map<String, dynamic>> rows,
  ) async {
    try {
      // Load template bytes
      final templateBytes = await loadTemplateBytes(book.templateCode);
      if (templateBytes == null) {
        print('Template file not found for: ${book.templateCode}');
        return null;
      }

      // Get template definition
      final template = TemplateRegistry.getTemplate(book.templateCode);
      if (template == null) return null;

      // Create output file
      final file = await _createWordFile(
        book,
        rows,
        template,
        templateBytes,
      );

      return file;
    } catch (e) {
      print('Error exporting to Word: $e');
      return null;
    }
  }

  /// Load template bytes from assets
  static Future<List<int>?> loadTemplateBytes(String templateCode) async {
    try {
      final filename = _templateFiles[templateCode];
      if (filename == null) {
        print('Unknown template code: $templateCode');
        return null;
      }

      final path = '$_templateDir/$filename';
      final bytes = await rootBundle.load(path);
      // Use toList() to create a modifiable and growable copy of the bytes
      return bytes.buffer
          .asUint8List(bytes.offsetInBytes, bytes.lengthInBytes)
          .toList();
    } catch (e) {
      print('Error loading template: $e');
      return null;
    }
  }

  /// Create Word file with populated data
  static Future<File?> _createWordFile(
    AccountingBook book,
    List<Map<String, dynamic>> rows,
    TemplateDefinition template,
    List<int> templateBytes,
  ) async {
    try {
      final docx = await DocxTemplate.fromBytes(templateBytes);

      final content = Content();

      // Top level fields (header)
      content.add(TextContent('bookName', template.templateName));
      content.add(TextContent('bookCode', book.bookCode));
      content.add(TextContent('periodId', book.periodId.toString()));
      content.add(TextContent('exportedAt', DateFormatter.formatDateTime(DateTime.now())));

      // Table rows
      // We assume the template has a table with a tag matching the templateCode (e.g., 'table_S1a')
      // OR a generic 'items' tag for the repeating part.
      // Based on common patterns, let's look for a table.
      
      final tableRows = <RowContent>[];
      for (final row in rows) {
        final rowContent = RowContent();
        for (final field in template.fields) {
          final val = row[field.fieldCode];
          final formattedVal = _formatCellValue(val, field.fieldType) ?? '';
          rowContent.add(TextContent(field.fieldCode, formattedVal));
        }
        tableRows.add(rowContent);
      }

      // Try to find the items table
      content.add(TableContent('items', tableRows));

      final buf = await docx.generate(content);

      if (buf == null) return null;

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${book.bookCode}_${DateTime.now().millisecondsSinceEpoch}.docx';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(buf);

      return file;
    } catch (e) {
      print('Error creating Word file: $e');
      return null;
    }
  }

  /// Share exported file
  static Future<void> shareExportedFile(File file) async {
    try {
      final path = file.absolute.path;
      await Share.shareXFiles(
        [XFile(path, mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')],
        text: 'Exported accounting book',
      );
    } catch (e) {
      print('Error sharing file: $e');
    }
  }

  /// Format cell value based on field type
  static String? _formatCellValue(
    dynamic value,
    String fieldType,
  ) {
    if (value == null) return '-';

    switch (fieldType) {
      case 'decimal':
        if (value is num) {
          return CurrencyFormatter.formatVND(value);
        }
        if (value is String) {
          try {
            return CurrencyFormatter.formatVND(int.parse(value));
          } catch (_) {
            return value;
          }
        }
        return value.toString();

      case 'date':
        if (value is String) {
          try {
            final date = DateTime.parse(value);
            return '${date.day}/${date.month.toString().padLeft(2, '0')}/${date.year}';
          } catch (_) {
            return value;
          }
        }
        return value.toString();

      case 'auto_increment':
        return value.toString();

      case 'text':
        return value.toString();

      default:
        return value.toString();
    }
  }

  /// Calculate formula value
  static String? calculateFormulaValue(
    String expression,
    List<Map<String, dynamic>> rows,
  ) {
    try {
      if (expression.startsWith('SUM(')) {
        final match = RegExp(r'SUM\((\w+)\)').firstMatch(expression);
        if (match != null) {
          final fieldCode = match.group(1);
          final sum = rows.fold<num>(0, (prev, row) {
            final val = row[fieldCode];
            if (val is num) return prev + val;
            if (val is String) {
              try {
                return prev + num.parse(val);
              } catch (_) {
                return prev;
              }
            }
            return prev;
          });
          return CurrencyFormatter.formatVND(sum);
        }
      }

      // Add more formula types as needed
      return null;
    } catch (e) {
      print('Error calculating formula: $e');
      return null;
    }
  }

  /// Prepare book data for reference
  static Map<String, dynamic> prepareBookData(
    AccountingBook book,
    List<Map<String, dynamic>> rows,
  ) {
    final template = TemplateRegistry.getTemplate(book.templateCode);
    if (template == null) return {};

    return {
      'bookCode': book.bookCode,
      'templateCode': book.templateCode,
      'periodId': book.periodId,
      'groupNumber': book.groupNumber,
      'taxMethod': book.taxMethod,
      'status': book.status,
      'columns': template.displayColumns
          .map((field) => {
                'code': field.fieldCode,
                'label': field.fieldLabel,
                'type': field.fieldType,
              })
          .toList(),
      'rowCount': rows.length,
      'exportedAt': DateTime.now().toString(),
    };
  }
}
