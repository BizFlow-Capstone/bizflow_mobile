import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/reference/presentation/bloc/reference_bloc.dart';
import '../../../../core/reference/presentation/bloc/reference_event.dart';
import '../../../../core/reference/presentation/bloc/reference_state.dart';
import '../../../../core/reference/data/reference_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/widgets/app_button.dart';

class GLFilterBottomSheet extends StatefulWidget {
  final List<String> currentTransactionTypes;
  final List<String> currentReferenceTypes;
  final List<String> currentMoneyChannels;
  final DateTime? currentFromDate;
  final DateTime? currentToDate;
  final String currentViewMode;

  const GLFilterBottomSheet({
    super.key,
    required this.currentTransactionTypes,
    required this.currentReferenceTypes,
    required this.currentMoneyChannels,
    this.currentFromDate,
    this.currentToDate,
    required this.currentViewMode,
  });

  @override
  State<GLFilterBottomSheet> createState() => _GLFilterBottomSheetState();
}

class _GLFilterBottomSheetState extends State<GLFilterBottomSheet> {
  late List<String> _selectedTransactionTypes;
  late List<String> _selectedReferenceTypes;
  late List<String> _selectedMoneyChannels;
  DateTime? _fromDate;
  DateTime? _toDate;
  late String _viewMode;
  bool _isReset = false;

  String _extractViewModeCode(dynamic raw) {
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return 'audit';

    if (text == 'audit' || text == 'effective') {
      return text;
    }

    final codeMatch = RegExp(r'code\s*:\s*([a-zA-Z_\-]+)').firstMatch(text);
    final code = codeMatch?.group(1)?.trim().toLowerCase();
    if (code == 'audit' || code == 'effective') {
      return code!;
    }

    final lowered = text.toLowerCase();
    if (lowered.contains('effective')) return 'effective';
    return 'audit';
  }

  String _viewModeLabel(AppLocalizations l10n, String code) {
    if (code == 'effective') {
      return l10n.translate('accounting.gl_view_effective');
    }
    return l10n.translate('accounting.gl_view_audit');
  }

  @override
  void initState() {
    super.initState();
    _selectedTransactionTypes = List.from(widget.currentTransactionTypes);
    _selectedReferenceTypes = List.from(widget.currentReferenceTypes);
    _selectedMoneyChannels = List.from(widget.currentMoneyChannels);
    _fromDate = widget.currentFromDate;
    _toDate = widget.currentToDate;
    _viewMode = _extractViewModeCode(widget.currentViewMode);
  }

  void _apply() {
    Navigator.of(context).pop({
      'transactionTypes': _selectedTransactionTypes,
      'referenceTypes': _selectedReferenceTypes,
      'moneyChannels': _selectedMoneyChannels,
      'fromDate': _fromDate,
      'toDate': _toDate,
      'viewMode': _viewMode,
      'resetDates': _isReset,
    });
  }

  void _clear() {
    setState(() {
      _selectedTransactionTypes.clear();
      _selectedReferenceTypes.clear();
      _selectedMoneyChannels.clear();
      _fromDate = null;
      _toDate = null;
      _viewMode = 'audit';
      _isReset = true;
    });
    // Auto-apply the cleared filters
    Future.delayed(const Duration(milliseconds: 100), _apply);
  }

  Future<void> _selectDate(bool isFromDate) async {
    final initialDate = isFromDate
        ? (_fromDate ?? DateTime.now())
        : (_toDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (isFromDate) {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
          _toDate = _fromDate;
        }
      } else {
        _toDate = picked;
        if (_fromDate != null && _fromDate!.isAfter(_toDate!)) {
          _fromDate = _toDate;
        }
      }
    });
  }

  Widget _buildMultiSelectFilter({
    required String title,
    required List<ReferenceItem> options,
    required List<String> selected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .where((item) => item.label.trim().isNotEmpty)
              .map((item) {
            final isSelected = selected.contains(item.code);
            return FilterChip(
              label: Text(item.label),
              selected: isSelected,
              onSelected: (checked) {
                setState(() {
                  if (checked) {
                    selected.add(item.code);
                  } else {
                    selected.remove(item.code);
                  }
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('product.filter_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(color: Colors.grey.shade200),
            Expanded(
              child: BlocBuilder<ReferenceBloc, ReferenceState>(
                builder: (context, state) {
                  if (state is ReferenceInitial) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      context.read<ReferenceBloc>().add(
                        LoadAllReferencesRequested(),
                      );
                    });
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ReferenceLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ReferenceError) {
                    return Center(child: Text(state.message));
                  }

                  if (state is! ReferenceLoaded) {
                    return Center(
                      child: Text(
                        l10n.translate('accounting.gl_filter_load_failed'),
                      ),
                    );
                  }

                  final refs = state.references;
                  final transactionTypes =
                      refs['generalLedgerTransactionTypes'] ?? <ReferenceItem>[];
                  final referenceTypes =
                      refs['generalLedgerReferenceTypes'] ?? <ReferenceItem>[];
                  final moneyChannels = refs['moneyChannelTypes'] ?? <ReferenceItem>[];
                    final rawViewModes =
                      refs['generalLedgerViewModes'] ?? <ReferenceItem>[];
                    final viewModes = rawViewModes
                      .map((item) => _extractViewModeCode(item.code))
                      .where((mode) => mode == 'audit' || mode == 'effective')
                      .toSet()
                      .toList();
                    if (viewModes.isEmpty) {
                    viewModes.addAll(const <String>['audit', 'effective']);
                    }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          context.tr('accounting.gl_view_mode'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: viewModes.map((mode) {
                            final isSelected = _viewMode == mode;
                            return ChoiceChip(
                              label: Text(_viewModeLabel(l10n, mode)),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (!selected) return;
                                setState(() => _viewMode = mode);
                              },
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('accounting.gl_filter_time'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _fromDate != null
                                            ? DateFormatter.formatDate(_fromDate)
                                            : context.tr('accounting.from_date'),
                                        style: TextStyle(
                                          color: _fromDate != null
                                              ? AppColors.textPrimary
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey.shade500,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('-', style: TextStyle(color: Colors.grey.shade500)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _toDate != null
                                            ? DateFormatter.formatDate(_toDate)
                                            : context.tr('accounting.to_date'),
                                        style: TextStyle(
                                          color: _toDate != null
                                              ? AppColors.textPrimary
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey.shade500,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildMultiSelectFilter(
                          title: context.tr('accounting.gl_filter_transaction'),
                          options: transactionTypes,
                          selected: _selectedTransactionTypes,
                        ),
                        const SizedBox(height: 16),
                        _buildMultiSelectFilter(
                          title: context.tr('accounting.gl_filter_reference'),
                          options: referenceTypes,
                          selected: _selectedReferenceTypes,
                        ),
                        const SizedBox(height: 16),
                        _buildMultiSelectFilter(
                          title: context.tr('accounting.gl_filter_channel'),
                          options: moneyChannels,
                          selected: _selectedMoneyChannels,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: context.tr('product.reset_filters'),
                      type: AppButtonType.outlined,
                      onPressed: _clear,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      label: context.tr('product.apply_filters'),
                      type: AppButtonType.primary,
                      onPressed: _apply,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
