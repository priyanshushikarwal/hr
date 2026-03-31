import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../shared/layouts/header.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../domain/providers/company_settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _officeWifiController = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _officeWifiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wifiSetting = ref.watch(officeWifiSsidsProvider);

    wifiSetting.whenData((value) {
      if (!_initialized) {
        _officeWifiController.text = value;
        _initialized = true;
      }
    });

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Settings',
            subtitle: 'Configure office attendance Wi-Fi for employees',
            breadcrumbs: ['Home', 'Settings'],
          ),
          ContentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        AppIcons.attendance,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Office Wi-Fi Attendance',
                            style: AppTypography.titleMedium,
                          ),
                          Text(
                            'Employees can mark attendance only when connected to one of these Wi-Fi names.',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Allowed Wi-Fi SSIDs',
                  style: AppTypography.formLabel,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _officeWifiController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Example:\nOffice_Main_Wifi\nDoonInfra_Office\nJaipur_Branch',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Enter one Wi-Fi name per line. The employee app will compare the connected SSID with this list.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.lg),
                wifiSetting.when(
                  data: (_) => const SizedBox.shrink(),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      'Failed to load settings: $error',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    PrimaryButton(
                      text: _isSaving ? 'Saving...' : 'Save Wi-Fi Settings',
                      icon: _isSaving ? null : AppIcons.save,
                      onPressed: _isSaving ? null : _saveSettings,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(companySettingsControllerProvider)
          .saveOfficeWifiSsids(_officeWifiController.text.trim());
      ref.invalidate(officeWifiSsidsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Office Wi-Fi settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
