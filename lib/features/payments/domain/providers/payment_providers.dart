import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/network_service.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

class PaymentListState {
  final List<PaymentRecord> payments;
  final bool isLoading;
  final String? error;
  final int selectedMonth;
  final int selectedYear;

  const PaymentListState({
    this.payments = const [],
    this.isLoading = false,
    this.error,
    required this.selectedMonth,
    required this.selectedYear,
  });

  PaymentListState copyWith({
    List<PaymentRecord>? payments,
    bool? isLoading,
    String? error,
    int? selectedMonth,
    int? selectedYear,
  }) {
    return PaymentListState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }

  double get totalNet => payments.fold(0, (s, p) => s + p.netSalary);
  int get pendingCount => payments.where((p) => p.status == 'pending').length;
  int get processedCount =>
      payments.where((p) => p.status == 'processed').length;
  int get paidCount => payments.where((p) => p.status == 'paid').length;
}

class PaymentListNotifier extends StateNotifier<PaymentListState> {
  final PaymentRepository _repository;
  final Ref _ref;

  PaymentListNotifier(this._repository, this._ref)
    : super(
        PaymentListState(
          selectedMonth: DateTime.now().month,
          selectedYear: DateTime.now().year,
        ),
      ) {
    loadPayments();
  }

  bool get _isOnline =>
      _ref.read(networkStatusProvider) == NetworkStatus.online;

  Future<void> loadPayments({int? month, int? year, String? status}) async {
    final m = month ?? state.selectedMonth;
    final y = year ?? state.selectedYear;
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedMonth: m,
      selectedYear: y,
    );

    try {
      final payments = await _repository.getPayments(
        month: m,
        year: y,
        status: status,
        isOnline: _isOnline,
      );
      state = state.copyWith(payments: payments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<PaymentRecord> processSalary(PaymentRecord record) async {
    try {
      final result = await _repository.processSalary(
        record,
        isOnline: _isOnline,
      );
      await loadPayments();
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> markAsPaid(
    String docId,
    String transactionNumber,
    String paymentMode,
  ) async {
    try {
      await _repository.updatePayment(docId, {
        'status': 'paid',
        'transactionNumber': transactionNumber,
        'paymentMode': paymentMode,
        'paymentDate': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, isOnline: _isOnline);
      await loadPayments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final paymentListProvider =
    StateNotifierProvider<PaymentListNotifier, PaymentListState>((ref) {
      final repo = ref.watch(paymentRepositoryProvider);
      return PaymentListNotifier(repo, ref);
    });
