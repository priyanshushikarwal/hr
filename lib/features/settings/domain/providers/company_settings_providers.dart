import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/domain/providers/auth_providers.dart';
import '../../data/repositories/company_settings_repository.dart';

final companySettingsRepositoryProvider = Provider<CompanySettingsRepository>((
  ref,
) {
  return CompanySettingsRepository();
});

final officeWifiSsidsProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(companySettingsRepositoryProvider);
  return repo.getSetting(CompanySettingsRepository.officeWifiSsidsKey);
});

final companySettingsControllerProvider =
    Provider<CompanySettingsController>((ref) {
      final repo = ref.watch(companySettingsRepositoryProvider);
      final user = ref.watch(currentUserProvider);
      return CompanySettingsController(repo, user?.userId);
    });

class CompanySettingsController {
  final CompanySettingsRepository _repository;
  final String? _updatedBy;

  CompanySettingsController(this._repository, this._updatedBy);

  Future<void> saveOfficeWifiSsids(String value) {
    return _repository.upsertSetting(
      key: CompanySettingsRepository.officeWifiSsidsKey,
      value: value,
      updatedBy: _updatedBy,
    );
  }
}
