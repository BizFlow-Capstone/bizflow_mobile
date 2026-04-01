import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/invoice_template_repository.dart';
import '../../domain/entities/invoice_template_entity.dart';
import 'invoice_template_event.dart';
import 'invoice_template_state.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../shared/cache/cache_manager.dart';

class InvoiceTemplateBloc extends Bloc<InvoiceTemplateEvent, InvoiceTemplateState> {
  final InvoiceTemplateRepository repository;

  // In-memory cache
  InvoiceTemplateEntity? _templateCache;

  InvoiceTemplateBloc({required this.repository})
    : super(const InvoiceTemplateInitial()) {
    on<LoadInvoiceTemplateRequested>(_onLoadInvoiceTemplateRequested);
    on<SaveInvoiceTemplateRequested>(_onSaveInvoiceTemplateRequested);
  }

  Future<String> _resolveCacheKey() async {
    final storage = await LocalStorage.getInstance();
    final email = (storage.getString(StorageKeys.currentUserEmail) ?? '')
        .trim()
        .toLowerCase();
    if (email.isNotEmpty) {
      return 'my_invoice_template:email:$email';
    }

    final phone = (storage.getString(StorageKeys.currentUserPhone) ?? '').trim();
    if (phone.isNotEmpty) {
      return 'my_invoice_template:phone:$phone';
    }

    final fullName = (storage.getString(StorageKeys.currentUserFullName) ?? '')
        .trim()
        .toLowerCase();
    if (fullName.isNotEmpty) {
      return 'my_invoice_template:name:$fullName';
    }

    return 'my_invoice_template:anonymous';
  }

  Future<InvoiceTemplateEntity> _refreshInvoiceTemplate() async {
    final template = await repository.getInvoiceTemplate();
    _templateCache = template;
    return template;
  }

  Future<void> _onLoadInvoiceTemplateRequested(
    LoadInvoiceTemplateRequested event,
    Emitter<InvoiceTemplateState> emit,
  ) async {
    emit(const InvoiceTemplateLoading());
    final cacheKey = await _resolveCacheKey();

    await CacheManager().fetchWithSWR<InvoiceTemplateEntity>(
      key: cacheKey,
      fetcher: ({cancelToken}) => _refreshInvoiceTemplate(),
      fromJson: (json) {
        return InvoiceTemplateEntity.fromMap(json['data'] as Map<String, dynamic>);
      },
      toJson: (data) {
        return {'data': data.toMap()};
      },
      onData: (data, isFromCache) {
        _templateCache = data;
        emit(InvoiceTemplateLoaded(template: data));
      },
      onError: (error) {
        emit(InvoiceTemplateFailure(message: error.toString()));
      },
    );
  }

  Future<void> _onSaveInvoiceTemplateRequested(
    SaveInvoiceTemplateRequested event,
    Emitter<InvoiceTemplateState> emit,
  ) async {
    emit(const InvoiceTemplateSaveInProgress());
    try {
      final updatedTemplate = await repository.updateInvoiceTemplate(event.request);
      final cacheKey = await _resolveCacheKey();

      _templateCache = updatedTemplate;

      // Update cache storage
      await CacheManager().set(cacheKey, {
        'data': _templateCache!.toMap(),
      });

      emit(const InvoiceTemplateSaveSuccess());
      emit(InvoiceTemplateLoaded(template: _templateCache!));
    } catch (e) {
      emit(InvoiceTemplateFailure(message: e.toString()));
    }
  }
}
