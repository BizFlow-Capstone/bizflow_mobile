import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/accounting_book.dart';
import '../../presentation/widgets/accounting_book_table_widget.dart';
import '../../presentation/widgets/s1a_book_widget.dart';
import '../../presentation/widgets/s2a_book_widget.dart';
import '../../data/services/word_export_service.dart';
import '../../data/repositories/accounting_repository.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';

class AccountingBookDetailPage extends StatefulWidget {
  final AccountingBook book;
  final String locationId;

  const AccountingBookDetailPage({
    super.key,
    required this.book,
    required this.locationId,
  });

  @override
  State<AccountingBookDetailPage> createState() =>
      _AccountingBookDetailPageState();
}

class _AccountingBookDetailPageState extends State<AccountingBookDetailPage> {
  late Future<BookSectionsResponse?> _sectionsFuture;
  late Future<List<Map<String, dynamic>>> _rowsFuture;

  @override
  void initState() {
    super.initState();
    _sectionsFuture = _loadSections();
    _rowsFuture = _loadAllRows();
  }

  Future<BookSectionsResponse?> _loadSections() async {
    try {
      return await context
          .read<AccountingRepository>()
          .getBookSections(
            locationId: widget.locationId,
            bookId: widget.book.bookId.toString(),
          );
    } catch (e) {
      // Fallback: if sections API fails, return null
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _loadAllRows() async {
    final repo = context.read<AccountingRepository>();
    final allRows = <Map<String, dynamic>>[];
    String? cursor;
    bool hasMore = true;
    while (hasMore) {
      final batch = await repo.getBookRows(
        locationId: widget.locationId,
        bookId: widget.book.bookId.toString(),
        cursor: cursor,
      );
      allRows.addAll(batch.rows);
      hasMore = batch.hasMore;
      cursor = batch.nextCursor;
    }
    return allRows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.displayName),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Object?>>(
        future: Future.wait([_sectionsFuture, _rowsFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: AppColors.error),
                  ),
                  SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _sectionsFuture = _loadSections();
                      _rowsFuture = _loadAllRows();
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final results = snapshot.data;
          final sectionsData = results?[0] as BookSectionsResponse?;
          final dataRows = (results?[1] as List<Map<String, dynamic>>?) ?? [];
          if (sectionsData == null) {
            return Center(
              child: Text(AppLocalizations.of(context).translate('common.no_data')),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                // Book info header
                _buildBookHeader(context),
                const Divider(height: 1),
                // Template-aware table
                Expanded(
                  child: _buildTemplateWidget(sectionsData, dataRows),
                ),
                // Export button
                _buildExportButton(context, sectionsData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTemplateWidget(BookSectionsResponse sectionsData, List<Map<String, dynamic>> dataRows) {
    final code = widget.book.templateCode.toUpperCase();
    switch (code) {
      case 'S1A':
        return S1aBookWidget(sections: sectionsData, dataRows: dataRows);
      case 'S2A':
        return S2aBookWidget(sections: sectionsData, dataRows: dataRows);
      default:
        // Fallback: use generic table for other templates and inject data rows
        // at data_placeholder positions.
        final allRows = <Map<String, dynamic>>[];
        for (final section in sectionsData.sections) {
          for (final row in section.rows) {
            final lineType = (row.values['lineType'] ?? '').toString();
            if (lineType == 'data_placeholder') {
              allRows.addAll(dataRows);
            } else {
              allRows.add(row.values);
            }
          }
        }
        for (final row in sectionsData.footerRows) {
          allRows.add(row.values);
        }
        return AccountingBookTableWidget(
          templateCode: widget.book.templateCode,
          rows: allRows,
          isLoading: false,
        );
    }
  }

  Widget _buildBookHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.book.templateName ?? widget.book.templateCode,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.book.status),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.book.status.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, BookSectionsResponse sectionsData) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.file_download),
          label: const Text('Export to Word'),
          onPressed: () => _handleExport(context, sectionsData),
        ),
      ),
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    BookSectionsResponse sectionsData,
  ) async {
    if (!context.mounted) return;

    final allowed = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.reportExport,
    );
    if (!allowed || !context.mounted) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting to Word...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Convert sections to flat row maps for export
    final rows = <Map<String, dynamic>>[];
    for (final section in sectionsData.sections) {
      for (final row in section.rows) {
        rows.add(row.values);
      }
    }
    for (final row in sectionsData.footerRows) {
      rows.add(row.values);
    }

    // Export to Word
    final exportedFile = await WordExportService.exportToWord(
      widget.book,
      rows,
    );

    if (!context.mounted) return;

    if (exportedFile != null) {
      // Share exported file
      await WordExportService.shareExportedFile(exportedFile);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sổ kế toán đã được xuất: ${widget.book.bookCode}.docx'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lỗi khi xuất file Word'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
