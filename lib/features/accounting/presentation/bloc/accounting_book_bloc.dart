import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/accounting_repository.dart';
import '../../domain/models/accounting_book.dart';

// Events
abstract class AccountingBookEvent {}

class LoadBooksRequested extends AccountingBookEvent {
  final String locationId;
  final String? periodId;

  LoadBooksRequested({required this.locationId, this.periodId});
}

class CreateBooksRequested extends AccountingBookEvent {
  final String locationId;
  final Map<String, dynamic> body;

  CreateBooksRequested({required this.locationId, required this.body});
}

// States
abstract class AccountingBookState {}

class AccountingBookInitial extends AccountingBookState {}

class AccountingBookLoading extends AccountingBookState {}

class AccountingBookLoaded extends AccountingBookState {
  final List<AccountingBook> books;
  AccountingBookLoaded(this.books);
}

class AccountingBookOperationSuccess extends AccountingBookState {
  final String message;
  final List<AccountingBook>? createdBooks;
  AccountingBookOperationSuccess(this.message, {this.createdBooks});
}

class AccountingBookError extends AccountingBookState {
  final String message;
  AccountingBookError(this.message);
}

// Bloc
class AccountingBookBloc extends Bloc<AccountingBookEvent, AccountingBookState> {
  final AccountingRepository _repository;

  AccountingBookBloc({required AccountingRepository repository})
      : _repository = repository,
        super(AccountingBookInitial()) {
    on<LoadBooksRequested>(_onLoadBooks);
    on<CreateBooksRequested>(_onCreateBooks);
  }

  Future<void> _onLoadBooks(
    LoadBooksRequested event,
    Emitter<AccountingBookState> emit,
  ) async {
    emit(AccountingBookLoading());
    try {
      final books = await _repository.listBooks(
        locationId: event.locationId,
        periodId: event.periodId,
      );
      emit(AccountingBookLoaded(books));
    } catch (e) {
      emit(AccountingBookError(e.toString()));
    }
  }

  Future<void> _onCreateBooks(
    CreateBooksRequested event,
    Emitter<AccountingBookState> emit,
  ) async {
    emit(AccountingBookLoading());
    try {
      final response = await _repository.createBooksForPeriod(
        locationId: event.locationId,
        body: event.body,
      );
      emit(AccountingBookOperationSuccess(
        response.message,
        createdBooks: response.createdBooks,
      ));
      // Reload books
      add(LoadBooksRequested(
        locationId: event.locationId,
        periodId: event.body['periodId']?.toString(),
      ));
    } catch (e) {
      emit(AccountingBookError(e.toString()));
    }
  }
}
