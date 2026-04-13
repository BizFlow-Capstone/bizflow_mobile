import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message_parser.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/context/business_context.dart';
import '../../../../shared/models/ocr_purchase_invoice_dto.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/utils/name_similarity.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../../debt/domain/entities/debtor_entity.dart';
import '../../../debt/presentation/bloc/debtor_bloc.dart';
import '../../../debt/presentation/bloc/debtor_event.dart';
import '../../../debt/presentation/bloc/debtor_state.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart';
import '../../../product/presentation/bloc/product_state.dart';
import '../../../subscription/domain/subscription_feature_codes.dart';
import '../../../subscription/presentation/utils/subscription_feature_guard.dart';
import '../bloc/order_bloc.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import 'order_payment_screen.dart';

class OrderFormScreen extends StatefulWidget {
  final String inputType; // 'audio', 'voice', or 'manual'
  final String? draftId;
  final OrderEntity? initialOrder;
  final String? pendingOrderId;

  const OrderFormScreen({
    super.key,
    required this.inputType,
    this.draftId,
    this.initialOrder,
    this.pendingOrderId,
  });

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  String _customerType = 'walkin'; // walkin | debtor
  DebtorEntity? _selectedDebtor;
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _documentNumberController =
      TextEditingController();
  DateTime? _documentDate;
  bool _isCreatingDebtorProfile = false;
  bool _isSavingDraft = false;
  bool _isProceedingPayment = false;
  bool _hasAttemptedDebtorAutoMatch = false;
  bool _showPurchaseInvoiceOcr = false;
  bool _isPurchaseInvoiceOcrProcessing = false;
  String? _purchaseInvoiceOcrImagePath;
  String? _purchaseInvoiceOcrError;
  OcrPurchaseInvoiceResultDto? _purchaseInvoiceOcrResult;
  List<String> _purchaseInvoiceOcrUnmatchedProducts = const [];
  int _purchaseInvoiceOcrMatchedCount = 0;
  final ImagePicker _imagePicker = ImagePicker();

  static const int _phoneLength = 10;
  late final String _draftId;
  String? _draftCreatedAtIso;
  String? _aiRawTranscript;
  String? _aiConfidence;

  final List<OrderItemEntity> _items = [];

  @override
  void initState() {
    super.initState();
    final timestampStr = DateTime.now().millisecondsSinceEpoch.toString();
    _draftId =
        widget.draftId ??
        'draft_${timestampStr.substring(timestampStr.length - 6)}';

    if (widget.initialOrder != null) {
      final order = widget.initialOrder!;
      _items.addAll(order.items);
      _customerNameController.text = order.customerName ?? '';
      _customerPhoneController.text = order.customerPhone ?? '';
      if (widget.inputType != 'manual') {
        final note = (order.note ?? '').trim();
        _aiRawTranscript = note.isNotEmpty ? note : null;
        _aiConfidence = order.aiConfidence;
        // Don't pre-fill notes with AI transcript
      } else {
        _notesController.text = order.note ?? '';
      }

      if (order.debtorId != null && order.debtorId! > 0) {
        _customerType = 'debtor';
        _selectedDebtor = DebtorEntity(
          debtorId: order.debtorId!,
          name: order.customerName ?? '',
          phone: order.customerPhone ?? '',
          businessLocationId: int.tryParse(order.locationId) ?? 0,
          businessLocationName: order.locationName,
          creditLimit: 0,
          currentBalance: 0,
          isActive: true,
        );
      } else if (order.debtAmount > 0) {
        // Auto-select debtor type if AI indicated debt
        _customerType = 'debtor';
      } else {
        _customerType = 'walkin';
      }
    }

    final locationId = int.tryParse(BusinessContext().currentBusinessId ?? '');
    if (locationId != null && locationId > 0) {
      context.read<DebtorBloc>().add(
        LoadActiveDebtorsByLocationRequested(locationId: locationId),
      );
    }
    _loadDraftIfNeeded();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    _documentNumberController.dispose();
    super.dispose();
  }

  Color _confidenceBackgroundColor(String? confidence) {
    switch (confidence?.toLowerCase()) {
      case 'high':
        return Colors.green.withValues(alpha: 0.1);
      case 'medium':
        return Colors.orange.withValues(alpha: 0.1);
      case 'low':
        return Colors.red.withValues(alpha: 0.1);
      default:
        return Colors.grey.withValues(alpha: 0.1);
    }
  }

  Color _confidenceTextColor(String? confidence) {
    switch (confidence?.toLowerCase()) {
      case 'high':
        return Colors.green[700]!;
      case 'medium':
        return Colors.orange[700]!;
      case 'low':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _confidenceLabel(AppLocalizations l10n, String? confidence) {
    switch (confidence?.toLowerCase()) {
      case 'high':
        return l10n.translate('accounting.ai_confidence_high');
      case 'medium':
        return l10n.translate('accounting.ai_confidence_medium');
      case 'low':
        return l10n.translate('accounting.ai_confidence_low');
      default:
        return confidence ?? '';
    }
  }

  String _normalizePersonName(String input) {
    const vietnameseMap = {
      'a': 'a',
      'à': 'a',
      'á': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'b': 'b',
      'c': 'c',
      'd': 'd',
      'đ': 'd',
      'e': 'e',
      'è': 'e',
      'é': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'g': 'g',
      'h': 'h',
      'i': 'i',
      'ì': 'i',
      'í': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'k': 'k',
      'l': 'l',
      'm': 'm',
      'n': 'n',
      'o': 'o',
      'ò': 'o',
      'ó': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'p': 'p',
      'q': 'q',
      'r': 'r',
      's': 's',
      't': 't',
      'u': 'u',
      'ù': 'u',
      'ú': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'v': 'v',
      'x': 'x',
      'y': 'y',
      'ỳ': 'y',
      'ý': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
    };

    final lower = input.trim().toLowerCase();
    final buffer = StringBuffer();

    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      final mapped = vietnameseMap[char] ?? char;
      if (RegExp(r'[a-z0-9 ]').hasMatch(mapped)) {
        buffer.write(mapped);
      } else {
        buffer.write(' ');
      }
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    var previous = List<int>.generate(s2.length + 1, (i) => i);

    for (var i = 0; i < s1.length; i++) {
      final current = List<int>.filled(s2.length + 1, 0);
      current[0] = i + 1;
      for (var j = 0; j < s2.length; j++) {
        final cost = s1[i] == s2[j] ? 0 : 1;
        current[j + 1] = [
          current[j] + 1,
          previous[j + 1] + 1,
          previous[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      previous = current;
    }

    return previous.last;
  }

  double _nameSimilarityScore(String sourceName, String targetName) {
    final source = _normalizePersonName(sourceName);
    final target = _normalizePersonName(targetName);
    if (source.isEmpty || target.isEmpty) return 0;
    if (source == target) return 1;

    final maxLength = source.length > target.length
        ? source.length
        : target.length;
    final distance = _levenshteinDistance(source, target);
    final editSimilarity = 1 - (distance / maxLength);

    final sourceTokens = source.split(' ').where((e) => e.isNotEmpty).toSet();
    final targetTokens = target.split(' ').where((e) => e.isNotEmpty).toSet();
    final intersectionCount = sourceTokens.intersection(targetTokens).length;
    final unionCount = sourceTokens.union(targetTokens).length;
    final tokenSimilarity = unionCount == 0
        ? 0
        : intersectionCount / unionCount;

    return (editSimilarity * 0.7) + (tokenSimilarity * 0.3);
  }

  DebtorEntity? _findBestDebtorMatch(
    String aiCustomerName,
    List<DebtorEntity> debtors,
  ) {
    final normalizedInput = _normalizePersonName(aiCustomerName);
    if (normalizedInput.length < 3) return null;

    DebtorEntity? bestDebtor;
    var bestScore = 0.0;

    for (final debtor in debtors) {
      final score = _nameSimilarityScore(aiCustomerName, debtor.name);
      if (score > bestScore) {
        bestScore = score;
        bestDebtor = debtor;
      }
    }

    // Only auto-select when similarity is strong enough.
    if (bestScore >= 0.82) {
      return bestDebtor;
    }
    return null;
  }

  void _maybeAutoSelectDebtor(List<DebtorEntity> debtors) {
    if (!mounted || _hasAttemptedDebtorAutoMatch) return;
    if (_selectedDebtor != null || debtors.isEmpty) return;

    final aiName = _customerNameController.text.trim();
    if (aiName.isEmpty) return;

    _hasAttemptedDebtorAutoMatch = true;
    final matchedDebtor = _findBestDebtorMatch(aiName, debtors);
    if (matchedDebtor == null) return;

    setState(() {
      _customerType = 'debtor';
      _selectedDebtor = matchedDebtor;
      _customerNameController.text = matchedDebtor.name;
      _customerPhoneController.text = matchedDebtor.phone;
    });
  }

  String _resolveDirectNetworkError(AppLocalizations l10n, Object error) {
    if (!ConnectivityService().isOnline) {
      return l10n.translate('error.no_internet');
    }

    if (error is ApiException && error.statusCode == -3) {
      return l10n.translate('error.no_internet');
    }

    final parsed = ApiErrorMessageParser.parse(
      error,
      fallback: l10n.translate('common.error_occurred'),
    );
    final normalized = parsed.toLowerCase();
    if (normalized.contains('khong ket noi') ||
        normalized.contains('network') ||
        normalized.contains('connection')) {
      return l10n.translate('error.no_internet');
    }
    return parsed;
  }

  Future<void> _pickPurchaseInvoiceImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile == null || !mounted) return;

      setState(() {
        _purchaseInvoiceOcrImagePath = pickedFile.path;
        _purchaseInvoiceOcrError = null;
        _purchaseInvoiceOcrResult = null;
        _purchaseInvoiceOcrUnmatchedProducts = const [];
        _purchaseInvoiceOcrMatchedCount = 0;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _purchaseInvoiceOcrError = _resolveDirectNetworkError(
          AppLocalizations.of(context),
          error,
        );
      });
    }
  }

  Future<List<ProductEntity>> _loadProductsForOcrMapping() async {
    final locationId = (BusinessContext().currentBusinessId ?? '').trim();
    if (locationId.isEmpty) {
      return const <ProductEntity>[];
    }

    final repository = context.read<ProductBloc>().repository;
    final cached = await repository.getCachedProducts(locationId);
    if (cached.isNotEmpty) {
      return cached;
    }

    try {
      return await repository.getLocationProducts(locationId);
    } catch (_) {
      return const <ProductEntity>[];
    }
  }

  List<Map<String, dynamic>> _normalizedSaleItemsForOcr(ProductEntity product) {
    if (product.saleItems.isEmpty) {
      return [
        {
          'key': '__default__',
          'saleItemId': null,
          'unit': (product.unit ?? '').trim(),
          'price': product.salePrice ?? product.price,
        },
      ];
    }

    return product.saleItems.map((item) {
      final rawId = item['saleItemId'] ?? item['SaleItemId'] ?? item['id'];
      int? saleItemId;
      if (rawId is num) {
        saleItemId = rawId.toInt();
      } else if (rawId is String) {
        saleItemId = int.tryParse(rawId);
      }

      final rawPrice = item['price'] ?? item['Price'];
      final unitPrice = rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice?.toString() ?? '') ??
                (product.salePrice ?? product.price);
      final rawUnit = (item['unit'] ?? item['Unit'] ?? '').toString().trim();
      final fallbackUnit = (product.unit ?? '').trim();

      return {
        'key': saleItemId?.toString() ?? '__default__',
        'saleItemId': saleItemId,
        'unit': rawUnit.isNotEmpty
            ? rawUnit
            : (fallbackUnit.isNotEmpty
                  ? fallbackUnit
                  : AppLocalizations.of(
                      context,
                    ).translate('order_create.default_unit')),
        'price': unitPrice,
      };
    }).toList();
  }

  Map<String, dynamic> _resolveSaleItemForOcr(
    ProductEntity product,
    String ocrUnit,
  ) {
    final saleItems = _normalizedSaleItemsForOcr(product);
    final normalizedOcrUnit = ocrUnit.trim();
    if (normalizedOcrUnit.isNotEmpty) {
      for (final saleItem in saleItems) {
        final unitName = (saleItem['unit'] ?? '').toString();
        if (NameSimilarity.score(normalizedOcrUnit, unitName) >= 0.9) {
          return saleItem;
        }
      }
    }
    return saleItems.first;
  }

  Future<void> _scanPurchaseInvoiceOcr() async {
    if (_isPurchaseInvoiceOcrProcessing) return;

    final l10n = AppLocalizations.of(context);
    final imagePath = _purchaseInvoiceOcrImagePath;
    if (imagePath == null || imagePath.trim().isEmpty) {
      setState(() {
        _purchaseInvoiceOcrError = l10n.translate(
          'order_create.ocr_select_local_image',
        );
      });
      return;
    }

    if (!ConnectivityService().isOnline) {
      setState(() {
        _purchaseInvoiceOcrError = l10n.translate('error.no_internet');
      });
      return;
    }

    final locationId = int.tryParse(BusinessContext().currentBusinessId ?? '');
    if (locationId == null || locationId <= 0) {
      setState(() {
        _purchaseInvoiceOcrError = l10n.translate('common.error_occurred');
      });
      return;
    }

    setState(() {
      _isPurchaseInvoiceOcrProcessing = true;
      _purchaseInvoiceOcrError = null;
    });

    try {
      final result = await context
          .read<OrderBloc>()
          .repository
          .ocrPurchaseInvoice(
            locationId: locationId,
            imageFile: File(imagePath),
          );
      final products = await _loadProductsForOcrMapping();
      final matchedItems = <String, OrderItemEntity>{};
      final unmatchedProducts = <String>[];

      for (final item in result.items) {
        final matchedProduct = NameSimilarity.findBestMatch<ProductEntity>(
          item.productName,
          products,
          (product) => product.name,
        );
        if (matchedProduct == null) {
          if (item.productName.trim().isNotEmpty) {
            unmatchedProducts.add(item.productName.trim());
          }
          continue;
        }

        final saleItem = _resolveSaleItemForOcr(matchedProduct, item.unit);
        final saleItemId = saleItem['saleItemId'] as int?;
        final unitName = saleItem['unit'] as String?;
        final itemKey =
            '${matchedProduct.id}_${saleItemId ?? unitName ?? 'default'}';
        final existing = matchedItems[itemKey];
        matchedItems[itemKey] = OrderItemEntity(
          productId: matchedProduct.id,
          saleItemId: saleItemId,
          unitName: unitName,
          productName: matchedProduct.name,
          price: (saleItem['price'] as num).toDouble(),
          quantity:
              (existing?.quantity ?? 0) +
              (item.quantity > 0 ? item.quantity.round() : 1),
          discount: existing?.discount ?? 0,
        );
      }

      final parsedInvoiceDate = DateTime.tryParse(
        result.invoiceDate?.trim() ?? '',
      );
      final hasFillableData =
          parsedInvoiceDate != null || matchedItems.isNotEmpty;

      setState(() {
        _purchaseInvoiceOcrResult = result;
        _purchaseInvoiceOcrMatchedCount = matchedItems.length;
        _purchaseInvoiceOcrUnmatchedProducts = unmatchedProducts;
        if (parsedInvoiceDate != null) {
          _documentDate = parsedInvoiceDate;
        }
        if (matchedItems.isNotEmpty) {
          _items
            ..clear()
            ..addAll(matchedItems.values);
        }
        _purchaseInvoiceOcrError = hasFillableData
            ? null
            : l10n.translate('order_create.ocr_no_fillable_data');
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _purchaseInvoiceOcrResult = null;
        _purchaseInvoiceOcrMatchedCount = 0;
        _purchaseInvoiceOcrUnmatchedProducts = const [];
        _purchaseInvoiceOcrError = _resolveDirectNetworkError(l10n, error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPurchaseInvoiceOcrProcessing = false;
        });
      }
    }
  }

  Widget _buildPurchaseInvoiceOcrError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 18, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseInvoiceOcrSummary(AppLocalizations l10n) {
    final result = _purchaseInvoiceOcrResult;
    if (result == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('order_create.ocr_result_title'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.translate('accounting.ai_confidence')}: ${_confidenceLabel(l10n, result.confidence)}',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          if ((result.invoiceDate?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.translate('stock_import.document_date')}: ${result.invoiceDate!.trim()}',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            l10n.translate(
              'order_create.ocr_matched_count',
              params: {'count': _purchaseInvoiceOcrMatchedCount.toString()},
            ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          if (_purchaseInvoiceOcrUnmatchedProducts.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${l10n.translate('order_create.ocr_unmatched_label')}: ${_purchaseInvoiceOcrUnmatchedProducts.join(', ')}',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLocationName =
        BusinessContext().currentBusinessName ??
        l10n.translate('common.no_data');

    final subTotal = _items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final totalDiscount = _items.fold<double>(
      0,
      (sum, item) => sum + item.discount,
    );
    final double amountAfterDiscount = (subTotal - totalDiscount)
        .clamp(0, double.infinity)
        .toDouble();
    final double total = amountAfterDiscount;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _saveLocalDraft(showFeedback: false);
        }
      },
      child: BlocListener<DebtorBloc, DebtorState>(
        listener: (context, state) {
          _maybeAutoSelectDebtor(state.activeDebtorsByLocation);
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.translate('order_create.form_title')),
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                await _saveLocalDraft(showFeedback: false);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              color: Colors.black,
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            actions: [
              TextButton(
                onPressed: _isSavingDraft
                    ? null
                    : () async {
                        setState(() => _isSavingDraft = true);
                        try {
                          await _saveLocalDraft(showFeedback: true);
                          if (mounted) {
                            Navigator.popUntil(
                              context,
                              ModalRoute.withName('/home'),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isSavingDraft = false);
                          }
                        }
                      },
                child: Text(
                  l10n.translate('order_create.save_draft'),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ],
            bottom: const AppSyncStatusText(),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Business Location
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.store, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.translate(
                                    'order_create.business_location',
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                Text(
                                  currentLocationName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // AI Transcript Section (only for voice/audio input)
                    if (_aiRawTranscript != null &&
                        _aiRawTranscript!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.purple.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.mic,
                                  size: 14,
                                  color: Colors.purple[700],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.translate(
                                    'order_create.voice_text_title',
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.subtitles_outlined,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SelectableText(
                                    _aiRawTranscript!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_aiConfidence != null &&
                                _aiConfidence!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _confidenceBackgroundColor(
                                    _aiConfidence,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${l10n.translate('accounting.ai_confidence')}: ${_confidenceLabel(l10n, _aiConfidence)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _confidenceTextColor(_aiConfidence),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showPurchaseInvoiceOcr = !_showPurchaseInvoiceOcr;
                          });
                        },
                        icon: Icon(
                          _showPurchaseInvoiceOcr
                              ? Icons.expand_less
                              : Icons.document_scanner_outlined,
                          size: 18,
                        ),
                        label: Text(
                          l10n.translate('order_create.ocr_toggle_button'),
                        ),
                      ),
                    ),
                    if (_showPurchaseInvoiceOcr) ...[
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.translate(
                                  'order_create.ocr_section_title',
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_purchaseInvoiceOcrImagePath != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_purchaseInvoiceOcrImagePath!),
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isPurchaseInvoiceOcrProcessing
                                          ? null
                                          : () => _pickPurchaseInvoiceImage(
                                              ImageSource.gallery,
                                            ),
                                      icon: const Icon(
                                        Icons.photo_library_outlined,
                                      ),
                                      label: Text(
                                        l10n.translate('common.source_gallery'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isPurchaseInvoiceOcrProcessing
                                          ? null
                                          : () => _pickPurchaseInvoiceImage(
                                              ImageSource.camera,
                                            ),
                                      icon: const Icon(
                                        Icons.camera_alt_outlined,
                                      ),
                                      label: Text(
                                        l10n.translate('common.source_camera'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isPurchaseInvoiceOcrProcessing
                                      ? null
                                      : _scanPurchaseInvoiceOcr,
                                  icon: _isPurchaseInvoiceOcrProcessing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.document_scanner_outlined,
                                        ),
                                  label: Text(
                                    l10n.translate(
                                      'order_create.ocr_scan_button',
                                    ),
                                  ),
                                ),
                              ),
                              if (_purchaseInvoiceOcrError != null) ...[
                                const SizedBox(height: 12),
                                _buildPurchaseInvoiceOcrError(
                                  _purchaseInvoiceOcrError!,
                                ),
                              ],
                              if (_purchaseInvoiceOcrResult != null) ...[
                                const SizedBox(height: 12),
                                _buildPurchaseInvoiceOcrSummary(l10n),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Customer Info Section
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.translate('order_create.customer_type'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: Text(
                                      l10n.translate(
                                        'order_create.customer_walkin',
                                      ),
                                    ),
                                    selected: _customerType == 'walkin',
                                    onSelected: (_) {
                                      setState(() {
                                        _customerType = 'walkin';
                                        _selectedDebtor = null;
                                        _customerNameController.clear();
                                        _customerPhoneController.clear();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ChoiceChip(
                                    label: Text(
                                      l10n.translate(
                                        'order_create.customer_loyal',
                                      ),
                                    ),
                                    selected: _customerType == 'debtor',
                                    onSelected: (_) {
                                      setState(() {
                                        _customerType = 'debtor';
                                      });

                                      final locationId = int.tryParse(
                                        BusinessContext().currentBusinessId ??
                                            '',
                                      );
                                      if (locationId != null &&
                                          locationId > 0) {
                                        context.read<DebtorBloc>().add(
                                          LoadActiveDebtorsByLocationRequested(
                                            locationId: locationId,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_customerType == 'debtor')
                              BlocBuilder<DebtorBloc, DebtorState>(
                                builder: (context, debtState) {
                                  final debtors =
                                      debtState.activeDebtorsByLocation;

                                  // Auto-select debtor only when name matching confidence is high.
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    _maybeAutoSelectDebtor(debtors);
                                  });

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => _openDebtorPicker(debtors),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: l10n.translate(
                                              'debt.select_debtor',
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.person_search,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _selectedDebtor == null
                                                      ? l10n.translate(
                                                          'debt.select_debtor',
                                                        )
                                                      : '${_selectedDebtor!.name} - ${_selectedDebtor!.phone}',
                                                  style: TextStyle(
                                                    color:
                                                        _selectedDebtor == null
                                                        ? Colors.grey[600]
                                                        : Colors.black,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const Icon(Icons.arrow_drop_down),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (_selectedDebtor != null) ...[
                                        const SizedBox(height: 12),
                                        _buildReadOnlyCustomerField(
                                          label: l10n.translate(
                                            'order_create.customer_name',
                                          ),
                                          icon: Icons.person,
                                          value: _selectedDebtor!.name,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildReadOnlyCustomerField(
                                          label: l10n.translate(
                                            'order_create.customer_phone',
                                          ),
                                          icon: Icons.phone,
                                          value: _selectedDebtor!.phone,
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            if (_customerType == 'walkin') ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isCreatingDebtorProfile
                                      ? null
                                      : _showCreateDebtProfileDialog,
                                  icon: _isCreatingDebtorProfile
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.person_add_alt_1),
                                  label: Text(
                                    l10n.translate(
                                      'order_create.create_debt_profile',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Product Info Section
                    Text(
                      l10n.translate('order_create.form_title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.translate('common.no_data'),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    else
                      ..._items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final p = entry.value;
                        final lineTotal = p.price * p.quantity;
                        final lineAfterDiscount = (lineTotal - p.discount)
                            .clamp(0, double.infinity);
                        final unitName = (p.unitName ?? '').trim();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${CurrencyFormatter.formatVND(p.price)}${unitName.isNotEmpty ? ' / $unitName' : ''} x ${p.quantity}',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${l10n.translate('order_create.discount')}: ${CurrencyFormatter.formatVND(p.discount)}',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 170,
                                      child: TextFormField(
                                        key: ValueKey(
                                          'discount_${p.productId}_$index',
                                        ),
                                        initialValue:
                                            CurrencyFormatter.formatNumber(
                                              p.discount,
                                            ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters:
                                            AppInputFormatters.withSqlInjectionGuard(
                                              inputFormatters: [
                                                CurrencyInputFormatter(),
                                              ],
                                            ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: l10n.translate(
                                            'order_create.discount',
                                          ),
                                          prefixText: '₫ ',
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                        ),
                                        onChanged: (value) {
                                          _updateItemDiscount(
                                            index,
                                            value,
                                            lineTotal,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.formatVND(
                                      lineAfterDiscount,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: l10n.translate('common.delete'),
                                    onPressed: () {
                                      setState(() {
                                        _items.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                    OutlinedButton.icon(
                      onPressed: _openProductPicker,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.translate('order_create.add_product')),
                    ),

                    const SizedBox(height: 24),

                    // Document Number
                    TextField(
                      controller: _documentNumberController,
                      decoration: InputDecoration(
                        labelText: 'Số chứng từ',
                        hintText: 'Nhập số chứng từ (nếu có)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Document Date
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _documentDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _documentDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Ngày chứng từ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 20,
                          ),
                        ),
                        child: Text(
                          _documentDate != null
                              ? DateFormatter.formatDate(_documentDate)
                              : 'Chọn ngày chứng từ (nếu có)',
                          style: _documentDate != null
                              ? null
                              : TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Summary Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.translate('order_create.sub_total')),
                        Text(CurrencyFormatter.formatVND(subTotal)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.translate('order_create.discount')),
                        Text('-${CurrencyFormatter.formatVND(totalDiscount)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.translate('order_create.total'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatVND(total),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _items.isEmpty || _isProceedingPayment
                    ? null
                    : () async {
                        if (_isProceedingPayment) return;
                        setState(() => _isProceedingPayment = true);

                        final allowed = await SubscriptionFeatureGuard.ensureAllowed(
                          context,
                          featureCode: SubscriptionFeatureCodes.orders,
                        );
                        if (!allowed) {
                          if (mounted) {
                            setState(() => _isProceedingPayment = false);
                          }
                          return;
                        }

                        final locationId = BusinessContext().currentBusinessId;

                        if (!mounted) {
                          setState(() => _isProceedingPayment = false);
                          return;
                        }

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderPaymentScreen(
                              totalAmount: total,
                              items: List.from(_items),
                              locationId: locationId,
                              locationName:
                                  BusinessContext().currentBusinessName,
                              localDraftId: widget.draftId ?? _draftId,
                              pendingOrderId: widget.pendingOrderId,
                              initialDebtorId: _customerType == 'debtor'
                                  ? _selectedDebtor?.debtorId
                                  : null,
                              initialDebtorName: _customerType == 'debtor'
                                  ? _selectedDebtor?.name
                                  : null,
                              customerName: _customerNameController.text.trim(),
                              customerPhone: _customerPhoneController.text
                                  .trim(),
                              note: _notesController.text.trim().isNotEmpty
                                  ? _notesController.text.trim()
                                  : null,
                              documentDate: _documentDate,
                              documentNumber:
                                  _documentNumberController.text
                                      .trim()
                                      .isNotEmpty
                                  ? _documentNumberController.text.trim()
                                  : null,
                            ),
                          ),
                        );
                        if (mounted) {
                          setState(() => _isProceedingPayment = false);
                        }
                      },
                child: Text(
                  l10n.translate('order_create.proceed_payment'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _hasDraftData() {
    if (_items.isNotEmpty) return true;
    if (_customerType == 'debtor' && _selectedDebtor != null) return true;
    if (_customerNameController.text.trim().isNotEmpty) return true;
    if (_customerPhoneController.text.trim().isNotEmpty) return true;
    return false;
  }

  Future<void> _loadDraftIfNeeded() async {
    final existingDraftId = widget.draftId;
    if (existingDraftId == null || existingDraftId.trim().isEmpty) return;

    final storage = await LocalStorage.getInstance();
    final raw = storage.getString(StorageKeys.orderLocalDrafts);
    if (raw == null || raw.trim().isEmpty) return;

    final decoded = jsonDecode(raw);
    if (decoded is! List) return;

    Map<String, dynamic>? draft;
    for (final item in decoded) {
      if (item is Map && item['id']?.toString() == existingDraftId) {
        draft = Map<String, dynamic>.from(item);
        break;
      }
    }
    if (draft == null || !mounted) return;

    double asDouble(dynamic value, {double fallback = 0}) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    int asInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    final itemsNode = draft['items'];
    final loadedItems = itemsNode is List
        ? itemsNode.whereType<Map>().map((rawItem) {
            final item = Map<String, dynamic>.from(rawItem);
            final saleItemRaw = item['saleItemId'];
            int? saleItemId;
            if (saleItemRaw is num) {
              saleItemId = saleItemRaw.toInt();
            } else if (saleItemRaw is String) {
              saleItemId = int.tryParse(saleItemRaw);
            }

            return OrderItemEntity(
              id: item['id']?.toString(),
              productId: item['productId']?.toString() ?? '',
              saleItemId: saleItemId,
              unitName: item['unitName']?.toString(),
              productName: item['productName']?.toString() ?? '',
              price: asDouble(item['price']),
              quantity: asInt(item['quantity'], fallback: 1),
              discount: asDouble(item['discount']),
              note: item['note']?.toString(),
            );
          }).toList()
        : <OrderItemEntity>[];

    setState(() {
      _customerType =
          (draft?['customerType']?.toString().trim().isNotEmpty ?? false)
          ? draft!['customerType'].toString()
          : 'walkin';
      _customerNameController.text = draft?['customerName']?.toString() ?? '';
      _customerPhoneController.text = draft?['customerPhone']?.toString() ?? '';
      _draftCreatedAtIso = draft?['createdAt']?.toString();
      _items
        ..clear()
        ..addAll(loadedItems);
    });
  }

  Map<String, dynamic> _buildDraftPayload() {
    final locationId = (BusinessContext().currentBusinessId ?? '').trim();
    final locationName = (BusinessContext().currentBusinessName ?? '').trim();
    final createdAt =
        _draftCreatedAtIso ?? DateTime.now().toUtc().toIso8601String();
    final updatedAt = DateTime.now().toUtc().toIso8601String();

    final subtotal = _items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final totalDiscount = _items.fold<double>(
      0,
      (sum, item) => sum + item.discount,
    );
    final totalAmount = (subtotal - totalDiscount)
        .clamp(0, double.infinity)
        .toDouble();

    return {
      'id': _draftId,
      'locationId': locationId,
      'locationName': locationName,
      'status': 'draft',
      'customerType': _customerType,
      'selectedDebtorId': _selectedDebtor?.debtorId,
      'selectedDebtorName': _selectedDebtor?.name,
      'customerName': _customerNameController.text.trim(),
      'customerPhone': _customerPhoneController.text.trim(),
      'subtotal': subtotal,
      'discountAmount': totalDiscount,
      'taxAmount': 0,
      'totalAmount': totalAmount,
      'items': _items
          .map(
            (item) => {
              'id': item.id,
              'productId': item.productId,
              'saleItemId': item.saleItemId,
              'unitName': item.unitName,
              'productName': item.productName,
              'price': item.price,
              'quantity': item.quantity,
              'discount': item.discount,
              'note': item.note,
            },
          )
          .toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Future<void> _saveLocalDraft({required bool showFeedback}) async {
    if (!_hasDraftData()) return;

    final storage = await LocalStorage.getInstance();
    final raw = storage.getString(StorageKeys.orderLocalDrafts);

    List<Map<String, dynamic>> drafts = [];
    if (raw != null && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        drafts = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    final payload = _buildDraftPayload();
    final index = drafts.indexWhere((item) => item['id'] == _draftId);
    if (index >= 0) {
      drafts[index] = payload;
    } else {
      drafts.insert(0, payload);
    }

    await storage.setString(StorageKeys.orderLocalDrafts, jsonEncode(drafts));

    if (!mounted || !showFeedback) return;
    AppSnackBar.show(
      context,
      message: AppLocalizations.of(
        context,
      ).translate('order_create.save_draft'),
      type: AppSnackBarType.success,
    );
  }

  void _updateItemDiscount(int index, String rawValue, double lineTotal) {
    final normalizedInput = rawValue.replaceAll(',', '').trim();
    final parsed = double.tryParse(normalizedInput) ?? 0;
    final normalized = parsed.clamp(0, lineTotal).toDouble();
    final oldItem = _items[index];

    setState(() {
      _items[index] = OrderItemEntity(
        id: oldItem.id,
        productId: oldItem.productId,
        saleItemId: oldItem.saleItemId,
        unitName: oldItem.unitName,
        productName: oldItem.productName,
        price: oldItem.price,
        quantity: oldItem.quantity,
        discount: normalized,
        note: oldItem.note,
      );
    });
  }

  Future<void> _openProductPicker() async {
    final l10n = AppLocalizations.of(context);
    final locationId = BusinessContext().currentBusinessId;

    if (locationId == null || locationId.trim().isEmpty) {
      AppSnackBar.show(
        context,
        message: l10n.translate('debt.location_required'),
        type: AppSnackBarType.warning,
      );
      return;
    }

    context.read<ProductBloc>().add(
      LoadProductsByLocationRequested(locationId: locationId),
    );

    final updatedItems = await showModalBottomSheet<List<OrderItemEntity>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<ProductBloc>(),
        child: _OrderProductPickerSheet(
          initialItems: _items,
          locationId: locationId,
        ),
      ),
    );

    if (!mounted || updatedItems == null) return;

    setState(() {
      _items
        ..clear()
        ..addAll(updatedItems);
    });
  }

  Future<void> _showCreateDebtProfileDialog() async {
    final allowed = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.debtManagement,
    );
    if (!allowed || !mounted) return;

    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();
    final creditLimitController = TextEditingController();

    final nameFocusNode = FocusNode();
    final phoneFocusNode = FocusNode();

    String? nameError;
    String? phoneError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.translate('debt.create_title')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      focusNode: nameFocusNode,
                      decoration: InputDecoration(
                        labelText: '${l10n.translate('order_create.customer_name')} *',
                        errorText: nameError,
                      ),
                      onChanged: (_) {
                        if (nameError != null) setState(() => nameError = null);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      focusNode: phoneFocusNode,
                      keyboardType: TextInputType.phone,
                      inputFormatters: AppInputFormatters.withSqlInjectionGuard(
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_phoneLength),
                        ],
                      ),
                      decoration: InputDecoration(
                        labelText: '${l10n.translate('order_create.customer_phone')} *',
                        errorText: phoneError,
                      ),
                      onChanged: (_) {
                        if (phoneError != null) setState(() => phoneError = null);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: l10n.translate('debt.address'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: l10n.translate('debt.note'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: creditLimitController,
                      keyboardType: TextInputType.number,
                      inputFormatters: AppInputFormatters.withSqlInjectionGuard(
                        inputFormatters: [CurrencyInputFormatter()],
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.translate('debt.credit_limit'),
                        suffixText: 'đ',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.translate('common.cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();

                    setState(() {
                      nameError = name.isEmpty ? l10n.translate('common.required_field') : null;
                      phoneError = phone.isEmpty ? l10n.translate('common.required_field') : null;
                    });

                    if (name.isEmpty) {
                      nameFocusNode.requestFocus();
                      return;
                    }

                    if (phone.isEmpty) {
                      phoneFocusNode.requestFocus();
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(l10n.translate('common.save')),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      nameFocusNode.dispose();
      phoneFocusNode.dispose();
    });

    if (confirmed != true || !mounted) return;

    await _createDebtProfile(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      notes: notesController.text.trim(),
      creditLimitText: creditLimitController.text.trim(),
    );
  }

  Future<void> _createDebtProfile({
    required String name,
    required String phone,
    required String address,
    required String notes,
    required String creditLimitText,
  }) async {
    if (_isCreatingDebtorProfile) return;

    final l10n = AppLocalizations.of(context);
    final locationId = int.tryParse(BusinessContext().currentBusinessId ?? '');
    final customerName = name;
    final customerPhone = phone;
    final creditLimit = creditLimitText.isEmpty
        ? null
        : double.tryParse(creditLimitText.replaceAll(',', ''));

    if (locationId == null || locationId <= 0) {
      AppSnackBar.show(
        context,
        message: l10n.translate('debt.location_required'),
        type: AppSnackBarType.warning,
      );
      return;
    }

    setState(() => _isCreatingDebtorProfile = true);

    final allowed = await SubscriptionFeatureGuard.ensureAllowed(
      context,
      featureCode: SubscriptionFeatureCodes.debtManagement,
    );
    if (!allowed) {
      if (mounted) {
        setState(() => _isCreatingDebtorProfile = false);
      }
      return;
    }

    try {
      final repository = context.read<DebtorBloc>().repository;
      final createdDebtor = await repository.createDebtor(
        businessLocationId: locationId,
        name: customerName,
        phone: customerPhone.isEmpty ? null : customerPhone,
        address: address.isEmpty ? null : address,
        notes: notes.isEmpty ? null : notes,
        creditLimit: creditLimit,
      );

      if (!mounted) return;
      if (createdDebtor == null || createdDebtor.debtorId <= 0) {
        AppSnackBar.show(
          context,
          message: l10n.translate('debt.create_failed'),
          type: AppSnackBarType.error,
        );
        return;
      }

      context.read<DebtorBloc>().add(
        LoadActiveDebtorsByLocationRequested(locationId: locationId),
      );

      setState(() {
        _customerType = 'debtor';
        _selectedDebtor = createdDebtor;
        _customerNameController.text = createdDebtor.name;
        _customerPhoneController.text = createdDebtor.phone;
      });

      AppSnackBar.show(
        context,
        message: l10n.translate('order_create.debt_profile_created'),
        type: AppSnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isCreatingDebtorProfile = false);
    }
  }

  Widget _buildReadOnlyCustomerField({
    required String label,
    required IconData icon,
    required String value,
  }) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      child: Text(value),
    );
  }

  Future<void> _openDebtorPicker(List<DebtorEntity> debtors) async {
    final l10n = AppLocalizations.of(context);
    final searchController = TextEditingController();

    final DebtorEntity? picked = await showModalBottomSheet<DebtorEntity>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final keyword = searchController.text.trim();
            final filtered = keyword.isEmpty
                ? debtors
                : debtors
                      .where((debtor) => debtor.phone.contains(keyword))
                      .toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('debt.select_debtor'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        keyboardType: TextInputType.phone,
                        inputFormatters:
                            AppInputFormatters.withSqlInjectionGuard(
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: l10n.translate(
                            'order_create.search_debtor_phone_dropdown',
                          ),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    setSheetState(() {});
                                  },
                                  icon: const Icon(Icons.close),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(l10n.translate('common.no_data')),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final debtor = filtered[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(debtor.name),
                                    subtitle: Text(debtor.phone),
                                    onTap: () =>
                                        Navigator.pop(sheetContext, debtor),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || picked == null) return;

    setState(() {
      _selectedDebtor = picked;
      _customerNameController.text = picked.name;
      _customerPhoneController.text = picked.phone;
    });
  }
}

class _OrderProductPickerSheet extends StatefulWidget {
  final List<OrderItemEntity> initialItems;
  final String locationId;

  const _OrderProductPickerSheet({
    required this.initialItems,
    required this.locationId,
  });

  @override
  State<_OrderProductPickerSheet> createState() =>
      _OrderProductPickerSheetState();
}

class _OrderProductPickerSheetState extends State<_OrderProductPickerSheet> {
  late final Map<String, int> _selectedQuantities;
  late final Map<String, String?> _selectedSaleItemKeyByProduct;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedQuantities = {
      for (final item in widget.initialItems) item.productId: item.quantity,
    };
    _selectedSaleItemKeyByProduct = {
      for (final item in widget.initialItems)
        item.productId: item.saleItemId?.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.translate('order_create.add_product'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _onDone,
                      child: Text(l10n.translate('common.done')),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.trim().toLowerCase();
                          });
                          context.read<ProductBloc>().add(
                            SearchProductsRequested(
                              locationId: widget.locationId,
                              query: value,
                            ),
                          );
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: l10n.translate('common.search_products'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _openBarcodeAddPanel,
                      tooltip: l10n.translate(
                        'order_create.barcode_add_tooltip',
                      ),
                      icon: const Icon(Icons.qr_code_scanner),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    if (state is ProductLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is ProductFailure) {
                      return Center(
                        child: Text(state.message, textAlign: TextAlign.center),
                      );
                    }

                    if (state is! ProductsLoaded) {
                      return Center(
                        child: Text(l10n.translate('common.no_data')),
                      );
                    }

                    final products = state.products.where((product) {
                      if (_searchQuery.isEmpty) return true;
                      final name = product.name.toLowerCase();
                      final barcode = (product.barcode ?? '').toLowerCase();
                      return name.contains(_searchQuery) ||
                          barcode.contains(_searchQuery);
                    }).toList();

                    if (products.isEmpty) {
                      return Center(
                        child: Text(l10n.translate('common.no_data')),
                      );
                    }

                    return ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final productId = product.id;
                        final saleItems = _normalizedSaleItems(product);
                        final selectedSaleItem = _resolveSelectedSaleItem(
                          productId,
                          saleItems,
                        );
                        final quantity = _selectedQuantities[productId] ?? 0;
                        final unitPrice = (selectedSaleItem['price'] as num)
                            .toDouble();
                        final selectedUnit =
                            (selectedSaleItem['unit'] as String?) ?? '';

                        return ListTile(
                          title: Text(product.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${CurrencyFormatter.formatVND(unitPrice)}${selectedUnit.isNotEmpty ? ' / $selectedUnit' : ''}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${l10n.translate('order_create.sale_unit_label')}:',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isDense: true,
                                  isExpanded: true,
                                  value: selectedSaleItem['key'] as String,
                                  items: saleItems
                                      .map(
                                        (saleItem) => DropdownMenuItem<String>(
                                          value: saleItem['key'] as String,
                                          child: Text(
                                            '${_displayUnitName(saleItem['unit'] as String?)} x${saleItem['quantity']} (${CurrencyFormatter.formatVND((saleItem['price'] as num).toDouble())})',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  selectedItemBuilder: (context) {
                                    return saleItems.map((saleItem) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '${_displayUnitName(saleItem['unit'] as String?)} x${saleItem['quantity']}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList();
                                  },
                                  onChanged: saleItems.length <= 1
                                      ? null
                                      : (value) {
                                          if (value == null) return;
                                          _setSaleItemKey(productId, value);
                                        },
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: quantity <= 0
                                    ? null
                                    : () =>
                                          _setQuantity(productId, quantity - 1),
                              ),
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '$quantity',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () =>
                                    _setQuantity(productId, quantity + 1),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setQuantity(String productId, int quantity) {
    final safeQuantity = quantity.clamp(0, 99999).toInt();
    setState(() {
      if (safeQuantity <= 0) {
        _selectedQuantities.remove(productId);
        _selectedSaleItemKeyByProduct.remove(productId);
      } else {
        _selectedQuantities[productId] = safeQuantity;
      }
    });
  }

  Future<void> _openBarcodeAddPanel() async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<ProductBloc>().state;
    final products = state is ProductsLoaded
        ? state.products
        : const <ProductEntity>[];

    if (products.isEmpty) {
      AppSnackBar.show(
        context,
        message: l10n.translate('common.no_data'),
        type: AppSnackBarType.warning,
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: _BarcodeOrderAddPanel(
            products: products,
            onAdd:
                ({
                  required String productId,
                  required String saleItemKey,
                  required int quantity,
                }) {
                  final current = _selectedQuantities[productId] ?? 0;
                  _setSaleItemKey(productId, saleItemKey);
                  _setQuantity(productId, current + quantity);
                },
          ),
        );
      },
    );
  }

  void _setSaleItemKey(String productId, String saleItemKey) {
    setState(() {
      _selectedSaleItemKeyByProduct[productId] = saleItemKey;
    });
  }

  void _onDone() {
    final state = context.read<ProductBloc>().state;
    final products = state is ProductsLoaded
        ? state.products
        : const <ProductEntity>[];

    final items = <OrderItemEntity>[];
    for (final product in products) {
      final quantity = _selectedQuantities[product.id] ?? 0;
      if (quantity <= 0) continue;

      final saleItems = _normalizedSaleItems(product);
      final selectedSaleItem = _resolveSelectedSaleItem(product.id, saleItems);
      final unitPrice = (selectedSaleItem['price'] as num).toDouble();
      final saleItemId = selectedSaleItem['saleItemId'] as int?;
      final unitName = selectedSaleItem['unit'] as String?;

      items.add(
        OrderItemEntity(
          productId: product.id,
          saleItemId: saleItemId,
          unitName: unitName,
          productName: product.name,
          price: unitPrice,
          quantity: quantity,
          discount: 0,
        ),
      );
    }

    Navigator.pop(context, items);
  }

  List<Map<String, dynamic>> _normalizedSaleItems(ProductEntity product) {
    if (product.saleItems.isEmpty) {
      return [
        {
          'key': '__default__',
          'saleItemId': null,
          'unit': (product.unit ?? '').trim(),
          'price': product.salePrice ?? product.price,
          'quantity': 1,
        },
      ];
    }

    return product.saleItems.map((item) {
      final dynamic rawId =
          item['saleItemId'] ?? item['SaleItemId'] ?? item['id'];
      int? saleItemId;
      if (rawId is num) {
        saleItemId = rawId.toInt();
      } else if (rawId is String) {
        saleItemId = int.tryParse(rawId);
      }

      final dynamic rawPrice = item['price'] ?? item['Price'];
      final unitPrice = rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice?.toString() ?? '') ??
                (product.salePrice ?? product.price);

      final dynamic rawQty = item['quantity'] ?? item['Quantity'];
      final qty = rawQty is num
          ? rawQty.toInt()
          : int.tryParse('${rawQty ?? 1}') ?? 1;

      final rawUnit = (item['unit'] ?? item['Unit'] ?? '').toString().trim();
      final fallbackUnit = (product.unit ?? '').trim();
      final unit = rawUnit.isNotEmpty
          ? rawUnit
          : (fallbackUnit.isNotEmpty
                ? fallbackUnit
                : AppLocalizations.of(
                    context,
                  ).translate('order_create.default_unit'));

      return {
        'key': saleItemId?.toString() ?? '__default__',
        'saleItemId': saleItemId,
        'unit': unit,
        'price': unitPrice,
        'quantity': qty,
      };
    }).toList();
  }

  Map<String, dynamic> _resolveSelectedSaleItem(
    String productId,
    List<Map<String, dynamic>> saleItems,
  ) {
    final selectedKey = _selectedSaleItemKeyByProduct[productId];
    if (selectedKey != null) {
      for (final saleItem in saleItems) {
        if (saleItem['key'] == selectedKey) {
          return saleItem;
        }
      }
    }
    return saleItems.first;
  }

  String _displayUnitName(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isNotEmpty
        ? normalized
        : AppLocalizations.of(context).translate('order_create.default_unit');
  }
}

class _BarcodeOrderAddPanel extends StatefulWidget {
  final List<ProductEntity> products;
  final void Function({
    required String productId,
    required String saleItemKey,
    required int quantity,
  })
  onAdd;

  const _BarcodeOrderAddPanel({required this.products, required this.onAdd});

  @override
  State<_BarcodeOrderAddPanel> createState() => _BarcodeOrderAddPanelState();
}

class _BarcodeOrderAddPanelState extends State<_BarcodeOrderAddPanel> {
  final MobileScannerController _scannerController = MobileScannerController();
  final Map<String, _ScannedPendingItem> _pendingItems = {};
  String? _scanHint;
  DateTime? _lastAcceptedScanAt;

  String _normalizeScannableCode(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return '';
    return normalized.replaceAll(RegExp(r'\s+'), '');
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _scanHint ??
                            l10n.translate('order_create.barcode_scan_hint'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _pendingItems.isEmpty
                  ? Center(
                      child: Text(
                        l10n.translate('order_create.barcode_scanned_empty'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n
                              .translate('order_create.barcode_scanned_title')
                              .replaceAll('{count}', '${_pendingItems.length}'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _pendingItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _pendingItems.values.elementAt(
                                index,
                              );
                              return _buildPendingItemCard(item);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final totalQty = _pendingItems.values.fold<int>(
                                0,
                                (sum, item) => sum + item.quantity,
                              );
                              for (final item in _pendingItems.values) {
                                widget.onAdd(
                                  productId: item.product.id,
                                  saleItemKey: item.selectedSaleItemKey,
                                  quantity: item.quantity,
                                );
                              }
                              _scannerController.stop();
                              AppSnackBar.show(
                                context,
                                message: l10n
                                    .translate(
                                      'order_create.barcode_added_to_order',
                                    )
                                    .replaceAll(
                                      '{productCount}',
                                      '${_pendingItems.length}',
                                    )
                                    .replaceAll('{itemCount}', '$totalQty'),
                                type: AppSnackBarType.success,
                              );
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.add_shopping_cart),
                            label: Text(
                              l10n.translate(
                                'order_create.barcode_add_and_close',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    final l10n = AppLocalizations.of(context);
    String? code;
    for (final barcode in capture.barcodes) {
      final value = (barcode.rawValue ?? barcode.displayValue ?? '').trim();
      if (value.isNotEmpty) {
        code = value;
        break;
      }
    }
    if (code == null || code.trim().isEmpty) return;

    final normalizedScannedCode = _normalizeScannableCode(code);
    if (normalizedScannedCode.isEmpty) return;

    final now = DateTime.now();
    if (_lastAcceptedScanAt != null &&
        now.difference(_lastAcceptedScanAt!).inMilliseconds < 800) {
      return;
    }
    _lastAcceptedScanAt = now;

    ProductEntity? matched;
    for (final product in widget.products) {
      final normalizedProductCode = _normalizeScannableCode(product.barcode);
      if (normalizedProductCode.isNotEmpty &&
          normalizedProductCode == normalizedScannedCode) {
        matched = product;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      if (matched == null) {
        _scanHint = l10n
            .translate('order_create.barcode_not_found')
            .replaceAll('{code}', code!);
        return;
      }

      final existing = _pendingItems[matched.id];
      if (existing != null) {
        existing.quantity = (existing.quantity + 1).clamp(1, 99999);
        _scanHint = l10n
            .translate('order_create.barcode_increased')
            .replaceAll('{name}', matched.name)
            .replaceAll('{quantity}', '${existing.quantity}');
        return;
      }

      final saleItems = _normalizedSaleItems(matched);
      final defaultKey = saleItems.first['key'] as String;
      _pendingItems[matched.id] = _ScannedPendingItem(
        product: matched,
        saleItems: saleItems,
        selectedSaleItemKey: defaultKey,
        quantity: 1,
      );
      _scanHint = l10n
          .translate('order_create.barcode_scanned')
          .replaceAll('{name}', matched.name);
    });
  }

  Widget _buildPendingItemCard(_ScannedPendingItem item) {
    final l10n = AppLocalizations.of(context);
    final selected = _resolveSelectedSaleItem(item);
    final selectedPrice = (selected['price'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() {
                    _pendingItems.remove(item.product.id);
                  });
                },
              ),
            ],
          ),
          Text(
            '${l10n.translate('order_create.price_label')}: ${CurrencyFormatter.formatVND(selectedPrice)}',
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: item.selectedSaleItemKey,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.translate('order_create.sale_unit_label'),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            items: item.saleItems
                .map(
                  (saleItem) => DropdownMenuItem<String>(
                    value: saleItem['key'] as String,
                    child: Text(
                      '${_displayUnitName(saleItem['unit'] as String?)} x${saleItem['quantity']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                item.selectedSaleItemKey = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${l10n.translate('order_create.quantity_label')}:'),
              const SizedBox(width: 8),
              IconButton(
                onPressed: item.quantity <= 1
                    ? null
                    : () {
                        setState(() {
                          item.quantity -= 1;
                        });
                      },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    item.quantity = (item.quantity + 1).clamp(1, 99999);
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _normalizedSaleItems(ProductEntity product) {
    if (product.saleItems.isEmpty) {
      return [
        {
          'key': '__default__',
          'saleItemId': null,
          'unit': (product.unit ?? '').trim().isEmpty
              ? AppLocalizations.of(
                  context,
                ).translate('order_create.default_unit')
              : (product.unit ?? '').trim(),
          'price': product.salePrice ?? product.price,
          'quantity': 1,
        },
      ];
    }

    return product.saleItems.map((item) {
      final dynamic rawId =
          item['saleItemId'] ?? item['SaleItemId'] ?? item['id'];
      int? saleItemId;
      if (rawId is num) {
        saleItemId = rawId.toInt();
      } else if (rawId is String) {
        saleItemId = int.tryParse(rawId);
      }

      final dynamic rawPrice = item['price'] ?? item['Price'];
      final unitPrice = rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice?.toString() ?? '') ??
                (product.salePrice ?? product.price);

      final dynamic rawQty = item['quantity'] ?? item['Quantity'];
      final qty = rawQty is num
          ? rawQty.toInt()
          : int.tryParse('${rawQty ?? 1}') ?? 1;

      final rawUnit = (item['unit'] ?? item['Unit'] ?? '').toString().trim();
      final fallbackUnit = (product.unit ?? '').trim();
      final unit = rawUnit.isNotEmpty
          ? rawUnit
          : (fallbackUnit.isNotEmpty
                ? fallbackUnit
                : AppLocalizations.of(
                    context,
                  ).translate('order_create.default_unit'));

      return {
        'key': saleItemId?.toString() ?? '__default__',
        'saleItemId': saleItemId,
        'unit': unit,
        'price': unitPrice,
        'quantity': qty,
      };
    }).toList();
  }

  Map<String, dynamic> _resolveSelectedSaleItem(_ScannedPendingItem item) {
    for (final saleItem in item.saleItems) {
      if (saleItem['key'] == item.selectedSaleItemKey) {
        return saleItem;
      }
    }
    return item.saleItems.first;
  }

  String _displayUnitName(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isNotEmpty
        ? normalized
        : AppLocalizations.of(context).translate('order_create.default_unit');
  }
}

class _ScannedPendingItem {
  final ProductEntity product;
  final List<Map<String, dynamic>> saleItems;
  String selectedSaleItemKey;
  int quantity;

  _ScannedPendingItem({
    required this.product,
    required this.saleItems,
    required this.selectedSaleItemKey,
    required this.quantity,
  });
}
