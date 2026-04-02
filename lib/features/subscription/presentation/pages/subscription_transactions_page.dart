import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/subscription_api_service.dart';
import '../../data/models/subscription_models.dart';

class SubscriptionTransactionsPage extends StatefulWidget {
  const SubscriptionTransactionsPage({super.key});

  @override
  State<SubscriptionTransactionsPage> createState() =>
      _SubscriptionTransactionsPageState();
}

class _SubscriptionTransactionsPageState
    extends State<SubscriptionTransactionsPage> {
  final List<SubscriptionTransactionDto> _items = [];
  int _page = 1;
  static const int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchPage();
    }
  }

  Future<void> _fetchPage({bool reset = false}) async {
    if (_isLoading) return;
    if (reset) {
      _page = 1;
      _hasMore = true;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiService = context.read<SubscriptionApiService>();
      final result = await apiService.getTransactions(
        page: _page,
        pageSize: _pageSize,
      );
      setState(() {
        if (reset) _items.clear();
        _items.addAll(result.items);
        _hasMore = result.hasMore;
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: AppColors.textPrimary,
        ),
        title: Text(
          l10n.translate('subscription.transactions_title'),
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.translate('sync.refresh'),
            onPressed: () => _fetchPage(reset: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchPage(reset: true),
        child: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchPage(reset: true),
              child: Text(l10n.translate('common.retry')),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('subscription.no_transactions'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _items.length + (_hasMore || _isLoading ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _TransactionCard(
          transaction: _items[index],
          l10n: l10n,
        );
      },
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final SubscriptionTransactionDto transaction;
  final AppLocalizations l10n;

  const _TransactionCard({required this.transaction, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(transaction.status);
    final statusIcon = _statusIcon(transaction.status);
    final date = _parseDate(transaction.paidAt ?? transaction.createdAt ?? '');
    final typeLabel = _typeLabel(transaction.transactionType, l10n);
    final amountFormatted = _formatAmount(transaction.amount, transaction.currency);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.planName ?? typeLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    typeLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountFormatted,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(transaction.status, l10n),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'SUCCESS':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'FAILED':
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'SUCCESS':
        return Icons.check_circle_outline_rounded;
      case 'PENDING':
        return Icons.access_time_rounded;
      case 'FAILED':
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'SUCCESS':
        return l10n.translate('subscription.tx_status_paid');
      case 'PENDING':
        return l10n.translate('subscription.tx_status_pending');
      case 'FAILED':
        return l10n.translate('subscription.tx_status_failed');
      case 'CANCELLED':
        return l10n.translate('subscription.tx_status_cancelled');
      default:
        return status;
    }
  }

  String _typeLabel(String type, AppLocalizations l10n) {
    switch (type.toUpperCase()) {
      case 'NEW':
        return l10n.translate('subscription.tx_type_new');
      case 'RENEWAL':
        return l10n.translate('subscription.tx_type_renewal');
      case 'UPGRADE':
        return l10n.translate('subscription.tx_type_upgrade');
      case 'DOWNGRADE':
        return l10n.translate('subscription.tx_type_downgrade');
      case 'REFUND':
        return l10n.translate('subscription.tx_type_refund');
      default:
        return type;
    }
  }

  String? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  String _formatAmount(double amount, String currency) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return '$formatted ${currency == 'VND' ? '₫' : currency}';
  }
}
