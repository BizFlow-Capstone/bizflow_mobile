import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/accounting_book.dart';
import '../../presentation/widgets/accounting_book_table_widget.dart';
import '../../presentation/widgets/s1a_book_widget.dart';
import '../../presentation/widgets/s2a_book_widget.dart';
import '../../presentation/widgets/s2d_book_widget.dart';
import '../../presentation/widgets/s2b_book_widget.dart';
import '../../presentation/widgets/s2c_book_widget.dart';
import '../../presentation/widgets/s2e_book_widget.dart';
import '../../presentation/widgets/s3a_book_widget.dart';
import '../../data/repositories/accounting_repository.dart';
import '../../data/services/excel_export_service.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_state.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/dialogs/app_dialog.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/context/user_profile_context.dart';

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
  bool _isShowingLoadErrorDialog = false;

  @override
  void initState() {
    super.initState();
    _sectionsFuture = _loadSections();
    _rowsFuture = _loadAllRows();
  }

  Future<BookSectionsResponse?> _loadSections() async {
    try {
      return await context.read<AccountingRepository>().getBookSections(
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

  void _showLoadErrorDialog(String message) {
    if (!mounted || _isShowingLoadErrorDialog) return;
    _isShowingLoadErrorDialog = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _isShowingLoadErrorDialog = false;
        return;
      }

      await AppDialog.error(
        context,
        title: AppLocalizations.of(context).translate('common.error'),
        message: message,
      );

      _isShowingLoadErrorDialog = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(widget.book.displayName),
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
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
            final errorMessage = ApiErrorMessageParser.parse(snapshot.error!);
            _showLoadErrorDialog(errorMessage);

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 36,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Không thể tải dữ liệu sổ kế toán',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _isShowingLoadErrorDialog = false;
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
              child: Text(
                AppLocalizations.of(context).translate('common.no_data'),
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                // Book info header
                _buildBookHeader(context),
                const Divider(height: 1),
                // Template-aware table
                Expanded(child: _buildTemplateWidget(sectionsData, dataRows)),
                // Export button
                _buildExportButton(context, sectionsData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTemplateWidget(
    BookSectionsResponse sectionsData,
    List<Map<String, dynamic>> dataRows,
  ) {
    final code = widget.book.templateCode.toUpperCase();
    switch (code) {
      case 'S1A':
        return S1aBookWidget(sections: sectionsData, dataRows: dataRows);
      case 'S2A':
        return S2aBookWidget(sections: sectionsData, dataRows: dataRows);
      case 'S2B':
        return S2bBookWidget(sections: sectionsData, dataRows: dataRows);
      case 'S2C':
        return S2cBookWidget(sections: sectionsData, dataRows: dataRows);
      case 'S2D':
        return S2dBookWidget(sections: sectionsData, dataRows: dataRows);
      case 'S2E':
        return S2eBookWidget(sections: sectionsData, dataRows: dataRows);
      case 'S3A':
        return S3aBookWidget(sections: sectionsData, dataRows: dataRows);
      default:
        // Fallback: use generic table for other templates and inject data rows
        // at data_placeholder positions.
        final allRows = <Map<String, dynamic>>[];
        final footerSignatures = <String>{};
        for (final section in sectionsData.sections) {
          for (final row in section.rows) {
            final lineType = row.lineType;
            if (lineType == 'data_placeholder') {
              allRows.addAll(
                dataRows.map(
                  (data) => {
                    ...data,
                    'lineType': (data['lineType'] ?? 'data').toString(),
                  },
                ),
              );
            } else {
              final mapped = _mapSectionRow(row);
              if (_isRowEmpty(mapped)) continue;
              allRows.add(mapped);
              if (lineType != 'data') {
                footerSignatures.add(_rowSignature(mapped));
              }
            }
          }
        }
        for (final row in sectionsData.footerRows) {
          final mapped = _mapSectionRow(row);
          if (_isRowEmpty(mapped)) continue;
          final signature = _rowSignature(mapped);
          if (footerSignatures.contains(signature)) continue;
          allRows.add(mapped);
          footerSignatures.add(signature);
        }
        return AccountingBookTableWidget(
          templateCode: widget.book.templateCode,
          rows: allRows,
          isLoading: false,
        );
    }
  }

  Map<String, dynamic> _mapSectionRow(SectionRowDto row) {
    return {
      ...row.values,
      'lineType': row.lineType,
      if (row.businessTypeId != null) 'businessTypeId': row.businessTypeId,
      if (row.section != null) 'section': row.section,
      if (row.taxType != null) 'taxType': row.taxType,
      if (row.taxRate != null) 'taxRate': row.taxRate,
    };
  }

  String _rowSignature(Map<String, dynamic> row) {
    final normalized = Map<String, dynamic>.from(row)
      ..removeWhere((key, value) => value == null || value.toString().isEmpty);
    final entries = normalized.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => '${e.key}:${e.value}').join('|');
  }

  bool _isRowEmpty(Map<String, dynamic> row) {
    final content = Map<String, dynamic>.from(row)
      ..remove('lineType')
      ..remove('businessTypeId')
      ..remove('section')
      ..remove('taxType')
      ..remove('taxRate');

    for (final value in content.values) {
      if (value == null) continue;
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty && normalized != '-') {
        return false;
      }
    }
    return true;
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
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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

  Widget _buildExportButton(
    BuildContext context,
    BookSectionsResponse sectionsData,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.download_outlined),
              label: const Text('Tải xuống'),
              onPressed: () =>
                  _handleExport(context, sectionsData, shareAfterExport: false),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.share_outlined),
              label: const Text('Chia sẻ'),
              onPressed: () =>
                  _handleExport(context, sectionsData, shareAfterExport: true),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    BookSectionsResponse sectionsData, {
    required bool shareAfterExport,
  }) async {
    if (!context.mounted) return;

    final allowed = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.reportExport,
    );
    if (!allowed || !context.mounted) return;

    AppSnackBar.info(
      context,
      shareAfterExport
          ? 'Đang chuẩn bị file Excel để chia sẻ...'
          : 'Đang tạo file Excel để tải xuống...',
    );

    try {
      final rows = await _rowsFuture;
      final headerInfo = _buildExportHeaderInfo(sectionsData);
      final files = await ExcelExportService.exportToExcelFiles(
        widget.book,
        rows,
        sectionsData: sectionsData,
        headerInfo: headerInfo,
      );
      if (files.isEmpty) {
        throw Exception('Không thể tạo file Excel');
      }

      if (!context.mounted) return;
      if (shareAfterExport) {
        await ExcelExportService.shareExportedFiles(files);
        if (!context.mounted) return;
        AppSnackBar.success(context, 'Đã sẵn sàng chia sẻ file Excel');
      } else {
        await ExcelExportService.saveExportedFilesToDownloads(files);
        if (!context.mounted) return;
        AppSnackBar.success(
          context,
          Platform.isAndroid
              ? 'Đã lưu file Excel vào Downloads'
              : 'Đã lưu file Excel thành công',
        );
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('AccountingBookDetailPage._handleExport error: $e\n$st');
      if (!context.mounted) return;
      AppSnackBar.error(context, ApiErrorMessageParser.parse(e));
    }
  }

  ExcelExportHeaderInfo _buildExportHeaderInfo(
    BookSectionsResponse sectionsData,
  ) {
    final businessContext = context.read<BusinessContext>();
    final userProfile = UserProfileContext();
    final locationState = context.read<LocationBloc>().state;

    var businessName = '';
    var locationName = '';
    String address = '';
    String taxCode = '';
    if (locationState is LocationsLoaded) {
      dynamic location;
      for (final loc in locationState.locations) {
        if (loc.id == widget.locationId) {
          location = loc;
          break;
        }
      }
      if (location != null) {
        businessName = (location.ownerName ?? '').trim();
        locationName = (location.name ?? '').trim();
        address = location.fullAddress;
        taxCode = (location.taxCode ?? '').trim();
      }
    }

    if (businessName.isEmpty) {
      businessName = (userProfile.fullName ?? '').trim();
    }
    if (businessName.isEmpty) {
      businessName = (businessContext.currentBusinessName ?? '').trim();
    }

    final periodLabel =
        '${sectionsData.lastCalculatedAt.month.toString().padLeft(2, '0')}/${sectionsData.lastCalculatedAt.year}';

    return ExcelExportHeaderInfo(
      businessName: businessName,
      taxCode: taxCode,
      address: address,
      locationName: locationName,
      periodLabel: periodLabel,
    );
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
