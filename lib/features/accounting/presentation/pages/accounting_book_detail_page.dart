import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/accounting_book.dart';
import '../../presentation/widgets/accounting_book_table_widget.dart';
import '../../data/services/word_export_service.dart';
import '../bloc/accounting_period_bloc.dart';
import '../../data/repositories/accounting_repository.dart';

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
  late Future<BookRowsResponse?> _rowsFuture;

  @override
  void initState() {
    super.initState();
    _rowsFuture = context
        .read<AccountingRepository>()
        .getBookRows(
          locationId: widget.locationId,
          bookId: widget.book.bookId.toString(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.bookCode),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<BookRowsResponse?>(
        future: _rowsFuture,
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
                      _rowsFuture = context
                          .read<AccountingRepository>()
                          .getBookRows(
                            locationId: widget.locationId,
                            bookId: widget.book.bookId.toString(),
                          );
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final rowsData = snapshot.data;
          if (rowsData == null) {
            return Center(
              child: Text(AppLocalizations.of(context).translate('common.no_data')),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                // Book info header
                _buildBookHeader(context),
                const Divider(),
                // Table data
                Expanded(
                  child: AccountingBookTableWidget(
                    templateCode: widget.book.templateCode,
                    rows: rowsData.rows,
                    isLoading: false,
                  ),
                ),
                // Export button
                _buildExportButton(context, rowsData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.book.bookCode,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Template: ${widget.book.templateCode}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
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
          SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Group: ${widget.book.groupNumber}',
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(
                    'Method: ${widget.book.taxMethod}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Period ID: ${widget.book.periodId}',
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(
                    'Created: ${_formatDate(widget.book.createdAt)}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, BookRowsResponse rowsData) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.file_download),
          label: const Text('Export to Word'),
          onPressed: () => _handleExport(context, rowsData),
        ),
      ),
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    BookRowsResponse rowsData,
  ) async {
    if (!context.mounted) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting to Word...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Export to Word
    final exportedFile = await WordExportService.exportToWord(
      widget.book,
      rowsData.rows,
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

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
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
