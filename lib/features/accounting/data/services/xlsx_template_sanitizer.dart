import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Normalizes malformed XLSX style numFmt ids so package:excel can decode
/// templates exported from WPS/Excel variants that write custom numFmtId < 164.
class XlsxTemplateSanitizer {
  const XlsxTemplateSanitizer._();

  static Uint8List sanitize(Uint8List xlsxBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(xlsxBytes, verify: false);
      final stylesIndex = archive.files.indexWhere(
        (f) => f.name == 'xl/styles.xml',
      );
      if (stylesIndex < 0) {
        print('XlsxTemplateSanitizer: no xl/styles.xml found');
        return xlsxBytes;
      }
      final styles = archive.files[stylesIndex];

      final raw = styles.content;
      final bytes = _toBytes(raw);
      if (bytes == null || bytes.isEmpty) {
        print(
          'XlsxTemplateSanitizer: could not read styles.xml content '
          '(type=${raw.runtimeType})',
        );
        return xlsxBytes;
      }

      var xml = utf8.decode(bytes, allowMalformed: true);

      // Collect IDs declared in <numFmt .../> AND <numFmt ...>...</numFmt>.
      final numFmtRegex = RegExp(
        r'<numFmt\b[^>]*\bnumFmtId="(\d+)"',
        caseSensitive: false,
      );
      final declaredIds = numFmtRegex
          .allMatches(xml)
          .map((m) => int.tryParse(m.group(1) ?? ''))
          .whereType<int>()
          .toList(growable: false);

      // Collect ALL usages of numFmtId in the file (including <xf> tags).
      final allUsedIds = RegExp(r'numFmtId="(\d+)"')
          .allMatches(xml)
          .map((m) => int.tryParse(m.group(1) ?? ''))
          .whereType<int>()
          .toSet();

      // Build remap for declared IDs that are < 164.
      final assignedIds = <int>{...allUsedIds};
      final remap = <int, int>{};
      var nextCustomId = 164;

      for (final id in declaredIds) {
        if (id >= 164) continue;
        if (remap.containsKey(id)) continue;
        while (assignedIds.contains(nextCustomId)) {
          nextCustomId++;
        }
        remap[id] = nextCustomId;
        assignedIds.add(nextCustomId);
        nextCustomId++;
      }

      if (remap.isNotEmpty) {
        print('XlsxTemplateSanitizer: remapping numFmtIds $remap');
        remap.forEach((oldId, newId) {
          xml = xml.replaceAll('numFmtId="$oldId"', 'numFmtId="$newId"');
        });
      }

      // Safety net: force any remaining <numFmt> declarations with id < 164.
      xml = _forceCustomNumFmtFloor(xml);

      final xmlBytes = utf8.encode(xml);
      final updatedStyles = ArchiveFile(
        styles.name,
        xmlBytes.length,
        xmlBytes,
      );

      final updatedArchive = Archive();
      for (var index = 0; index < archive.files.length; index++) {
        updatedArchive.addFile(
          index == stylesIndex ? updatedStyles : archive.files[index],
        );
      }

      final encoded = ZipEncoder().encode(updatedArchive);
      if (encoded == null) {
        print('XlsxTemplateSanitizer: ZipEncoder returned null');
        return xlsxBytes;
      }
      return Uint8List.fromList(encoded);
    } catch (e) {
      print('XlsxTemplateSanitizer: sanitize failed: $e');
      return xlsxBytes;
    }
  }

  static List<int>? _toBytes(dynamic content) {
    if (content is Uint8List) return content;
    if (content is List<int>) return content;
    if (content is String) return utf8.encode(content);
    // archive 3.x may return InputStreamBase
    try {
      if (content != null) {
        final asUint8 = (content as dynamic).toUint8List();
        if (asUint8 is Uint8List) return asUint8;
      }
    } catch (_) {}
    return null;
  }

  static String _forceCustomNumFmtFloor(String xml) {
    // Match both self-closing <numFmt .../> and open <numFmt ...> tags.
    final numFmtTagRegex = RegExp(
      r'<numFmt\b[^>]*\bnumFmtId="(\d+)"[^>]*/?>',
      caseSensitive: false,
    );
    final used = <int>{};
    for (final m in numFmtTagRegex.allMatches(xml)) {
      final id = int.tryParse(m.group(1) ?? '');
      if (id != null) used.add(id);
    }

    var nextId = 164;
    return xml.replaceAllMapped(numFmtTagRegex, (match) {
      final id = int.tryParse(match.group(1) ?? '') ?? 0;
      if (id >= 164) return match.group(0)!;
      while (used.contains(nextId)) {
        nextId++;
      }
      final replacement = match.group(0)!.replaceAll(
        'numFmtId="$id"',
        'numFmtId="$nextId"',
      );
      used.add(nextId);
      nextId++;
      return replacement;
    });
  }
}
