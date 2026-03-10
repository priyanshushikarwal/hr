import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/network_service.dart';
import '../../data/models/offer_letter_model.dart';
import '../../data/repositories/offer_letter_repository.dart';

final offerLetterRepositoryProvider = Provider<OfferLetterRepository>((ref) {
  return OfferLetterRepository();
});

class OfferLetterListState {
  final List<OfferLetter> letters;
  final bool isLoading;
  final String? error;

  const OfferLetterListState({
    this.letters = const [],
    this.isLoading = false,
    this.error,
  });

  OfferLetterListState copyWith({
    List<OfferLetter>? letters,
    bool? isLoading,
    String? error,
  }) {
    return OfferLetterListState(
      letters: letters ?? this.letters,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get draftCount => letters.where((l) => l.isDraft).length;
  int get approvedCount => letters.where((l) => l.isApproved).length;
  int get sentCount => letters.where((l) => l.isSent).length;
  int get acceptedCount => letters.where((l) => l.isAccepted).length;
}

class OfferLetterNotifier extends StateNotifier<OfferLetterListState> {
  final OfferLetterRepository _repository;
  final Ref _ref;

  OfferLetterNotifier(this._repository, this._ref)
    : super(const OfferLetterListState()) {
    loadOfferLetters();
  }

  bool get _isOnline =>
      _ref.read(networkStatusProvider) == NetworkStatus.online;

  Future<void> loadOfferLetters({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final letters = await _repository.getOfferLetters(
        status: status,
        isOnline: _isOnline,
      );
      state = OfferLetterListState(letters: letters);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createOfferLetter(OfferLetter letter) async {
    try {
      await _repository.createOfferLetter(letter, isOnline: _isOnline);
      await loadOfferLetters();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> approve(String docId, String approvedBy) async {
    try {
      await _repository.updateStatus(
        docId,
        'approved',
        approvedBy: approvedBy,
        isOnline: _isOnline,
      );
      await loadOfferLetters();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> markSent(String docId) async {
    try {
      await _repository.updateStatus(docId, 'sent', isOnline: _isOnline);
      await loadOfferLetters();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> markAccepted(String docId) async {
    try {
      await _repository.updateStatus(docId, 'accepted', isOnline: _isOnline);
      await loadOfferLetters();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> markRejected(String docId) async {
    try {
      await _repository.updateStatus(docId, 'rejected', isOnline: _isOnline);
      await loadOfferLetters();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final offerLetterProvider =
    StateNotifierProvider<OfferLetterNotifier, OfferLetterListState>((ref) {
      final repo = ref.watch(offerLetterRepositoryProvider);
      return OfferLetterNotifier(repo, ref);
    });
