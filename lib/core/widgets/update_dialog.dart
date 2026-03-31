import 'package:flutter/material.dart';
import '../services/updater_service.dart';
import '../theme/theme.dart';
import '../constants/app_icons.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;
  final String currentVersion;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.currentVersion,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final _updaterService = UpdaterService();
  double _progress = 0;
  bool _isDownloading = false;
  bool _isInstalling = false;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _isDownloading = true;
      _error = null;
    });

    try {
      await _updaterService.downloadAndInstall(
        widget.updateInfo,
        (progress) {
          setState(() {
            _progress = progress;
            if (progress >= 1.0) {
              _isInstalling = true;
            }
          });
        },
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _isInstalling = false;
        _error = 'Update failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(AppIcons.refresh, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Update Available', style: AppTypography.titleLarge),
                      const SizedBox(height: 4),
                      Text('A new version of the app is ready to install.', style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Versions
            Row(
              children: [
                _buildVersionBadge('Current', widget.currentVersion, AppColors.textTertiary),
                const SizedBox(width: 8),
                const Icon(AppIcons.chevronRight, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                _buildVersionBadge('Latest', widget.updateInfo.version, AppColors.success),
              ],
            ),
            const SizedBox(height: 24),

            // Release Notes
            Text('Release Notes', style: AppTypography.labelLarge),
            const SizedBox(height: 8),
            Container(
              height: 120,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.updateInfo.releaseNotes.isEmpty 
                      ? '• Performance improvements\n• Bug fixes and UI refinements' 
                      : widget.updateInfo.releaseNotes,
                  style: AppTypography.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Progress or Actions
            if (_isDownloading || _isInstalling) ...[
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isInstalling ? 'Installing files...' : 'Downloading update...',
                        style: AppTypography.labelSmall,
                      ),
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    color: AppColors.primary,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  if (_isInstalling) 
                    Text(
                      'The application will restart automatically.',
                      style: AppTypography.caption.copyWith(color: AppColors.warningDark, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ] else if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.error, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.errorDark))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _startUpdate,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _startUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Update Now'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVersionBadge(String label, String version, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: AppTypography.labelSmall.copyWith(color: color.withOpacity(0.8))),
          Text(version, style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
