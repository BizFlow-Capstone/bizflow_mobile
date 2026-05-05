import 'package:equatable/equatable.dart';

abstract class ReferenceEvent extends Equatable {
  const ReferenceEvent();

  @override
  List<Object> get props => [];
}

class LoadAllReferencesRequested extends ReferenceEvent {}

/// Clears the local cache and forces a fresh network fetch.
/// Use when the UI language changes so labels are re-fetched in the new locale.
class ForceReloadAllReferencesRequested extends ReferenceEvent {}
