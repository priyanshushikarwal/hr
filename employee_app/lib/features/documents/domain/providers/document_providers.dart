import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/realtime_service.dart';
import '../../data/models/employee_document_model.dart';
import '../../data/repositories/document_repository.dart';
import '../../../profile/domain/providers/profile_providers.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository();
});

final employeeDocumentsProvider = FutureProvider<List<EmployeeDocument>>((
  ref,
) async {
  final profile = await ref.watch(employeeProfileProvider.future);
  if (profile == null) return [];

  RealtimeService.instance.subscribeToEmployeeDocuments();
  final sub = RealtimeService.instance.documentStream.listen((event) {
    if (event.data['employeeId'] == profile.id) {
      ref.invalidateSelf();
    }
  });
  ref.onDispose(sub.cancel);

  final repository = ref.read(documentRepositoryProvider);
  return repository.getEmployeeDocuments(profile.id);
});

class DocumentNotifier extends StateNotifier<AsyncValue<void>> {
  final DocumentRepository _repository;
  final Ref _ref;

  DocumentNotifier(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> uploadDocument({
    required String filePath,
    required String fileName,
    required String documentType,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _ref.read(employeeProfileProvider.future);
      if (profile == null) throw Exception('Employee profile not loaded');

      await _repository.uploadDocument(
        employeeId: profile.id,
        filePath: filePath,
        fileName: fileName,
        documentType: documentType,
      );

      // Refresh list
      _ref.invalidate(employeeDocumentsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteDocument(String documentId, String fileId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteDocument(documentId, fileId);
      _ref.invalidate(employeeDocumentsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> replaceDocument({
    required String documentId,
    required String previousFileId,
    required String filePath,
    required String fileName,
    required String documentType,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _ref.read(employeeProfileProvider.future);
      if (profile == null) throw Exception('Employee profile not loaded');

      await _repository.replaceDocument(
        documentId: documentId,
        previousFileId: previousFileId,
        employeeId: profile.id,
        filePath: filePath,
        fileName: fileName,
        documentType: documentType,
      );

      _ref.invalidate(employeeDocumentsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final documentNotifierProvider =
    StateNotifierProvider<DocumentNotifier, AsyncValue<void>>((ref) {
      return DocumentNotifier(ref.watch(documentRepositoryProvider), ref);
    });
