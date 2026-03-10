import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/appwrite.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../auth/domain/providers/auth_providers.dart';
import '../../../profile/domain/providers/profile_providers.dart';

class VisitModeScreen extends ConsumerStatefulWidget {
  const VisitModeScreen({super.key});
  @override
  ConsumerState<VisitModeScreen> createState() => _VisitModeScreenState();
}

class _VisitModeScreenState extends ConsumerState<VisitModeScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isSubmitting = false;
  Position? _currentPosition;
  XFile? _capturedImage;

  // Form fields
  final _purposeController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _remarksController = TextEditingController();

  // Steps: 0 = form, 1 = camera, 2 = preview
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      if (mounted) {
        _showError('Camera Error', 'Could not initialize camera: $e');
      }
    }
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable GPS.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. Please enable from Settings.';
      }

      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) _showError('GPS Error', e.toString());
    }
  }

  void _showError(String title, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _purposeController.dispose();
    _clientNameController.dispose();
    _addressController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _goToCamera() {
    if (_purposeController.text.trim().isEmpty) {
      _showError('Required', 'Please enter the visit purpose');
      return;
    }
    if (_currentPosition == null) {
      _showError('GPS Required', 'GPS signal not acquired yet. Please wait.');
      return;
    }
    _initCamera();
    setState(() => _currentStep = 1);
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null) return;

    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = image;
        _currentStep = 2;
      });
    } catch (e) {
      _showError('Camera Error', 'Failed to take selfie');
    }
  }

  void _retake() {
    setState(() {
      _capturedImage = null;
      _currentStep = 1;
    });
  }

  Future<void> _submitVisit() async {
    if (_capturedImage == null || _currentPosition == null) return;
    final auth = ref.read(authProvider);
    final employeeId = auth.user?.employeeId ?? auth.user?.userId;
    if (employeeId == null) return;

    // Get employee profile for name/code
    final profile = ref.read(employeeProfileProvider).valueOrNull;

    setState(() => _isSubmitting = true);

    try {
      final appwrite = AppwriteService.instance;
      final nowIso = DateTime.now().toIso8601String();

      // 1. Upload Selfie to storage
      final fileName =
          'visit_${employeeId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRes = await appwrite.storage.createFile(
        bucketId: AppwriteConfig.visitSelfiesBucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(
          path: _capturedImage!.path,
          filename: fileName,
        ),
      );

      // 2. Create visit record in visits collection
      final visitData = <String, dynamic>{
        'employeeId': employeeId,
        'employeeName': profile?.fullName ?? (auth.user?.name ?? ''),
        'employeeCode': profile?.employeeCode ?? '',
        'purpose': _purposeController.text.trim(),
        'visitDate': nowIso,
        'selfieFileId': storageRes.$id,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'locationAddress':
            '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
        'selfieTimestamp': nowIso,
        'status': 'pending',
        'createdAt': nowIso,
        'updatedAt': nowIso,
      };

      // Add optional fields
      if (_clientNameController.text.trim().isNotEmpty) {
        visitData['clientName'] = _clientNameController.text.trim();
      }
      if (_addressController.text.trim().isNotEmpty) {
        visitData['visitAddress'] = _addressController.text.trim();
      }
      if (_remarksController.text.trim().isNotEmpty) {
        visitData['remarks'] = _remarksController.text.trim();
      }

      await appwrite.databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.visitsCollectionId,
        documentId: ID.unique(),
        data: visitData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Visit submitted successfully! HR will review it.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) _showError('Submission Failed', e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 0
            ? 'Visit Details'
            : _currentStep == 1
                ? 'Take Selfie'
                : 'Review & Submit'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() {
                if (_currentStep == 2) {
                  _capturedImage = null;
                }
                _currentStep = _currentStep > 0 ? _currentStep - 1 : 0;
              });
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // GPS Status Strip
            _buildGpsStrip(),

            // Step Indicator
            _buildStepIndicator(),

            // Content
            Expanded(
              child: _currentStep == 0
                  ? _buildFormStep()
                  : _currentStep == 1
                      ? _buildCameraStep()
                      : _buildPreviewStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: _currentPosition != null
          ? AppColors.statusVisit.withValues(alpha: 0.1)
          : AppColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(
            _currentPosition != null ? Icons.gps_fixed : Icons.gps_not_fixed,
            color: _currentPosition != null
                ? AppColors.statusVisit
                : AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _currentPosition != null
                  ? 'GPS Locked: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                  : 'Acquiring GPS Signal...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _currentPosition != null
                    ? AppColors.statusVisit
                    : AppColors.error,
              ),
            ),
          ),
          if (_currentPosition == null)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          _stepDot(0, 'Details'),
          _stepLine(0),
          _stepDot(1, 'Selfie'),
          _stepLine(1),
          _stepDot(2, 'Submit'),
        ],
      ),
    );
  }

  Widget _stepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.statusVisit : AppColors.backgroundSecondary,
            border: Border.all(
              color: isActive ? AppColors.statusVisit : AppColors.border,
              width: 2,
            ),
          ),
          child: Center(
            child: isActive && _currentStep > step
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : AppColors.textTertiary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppColors.statusVisit : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
        color: isActive ? AppColors.statusVisit : AppColors.border,
      ),
    );
  }

  // ==================== STEP 1: FORM ====================

  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Enter visit details, then take a selfie. Your GPS location will be captured automatically.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.infoDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Purpose (Required)
          Text('Visit Purpose *',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          TextField(
            controller: _purposeController,
            decoration: InputDecoration(
              hintText: 'e.g. Client meeting, Site inspection, Delivery...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.work_outline),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),

          // Client Name (Optional)
          Text('Client / Company Name',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          TextField(
            controller: _clientNameController,
            decoration: InputDecoration(
              hintText: 'e.g. ABC Enterprises (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.business_outlined),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),

          // Visit Address (Optional)
          Text('Visit Address',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: 'e.g. 123 MG Road, Delhi (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),

          // Remarks (Optional)
          Text('Remarks',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          TextField(
            controller: _remarksController,
            decoration: InputDecoration(
              hintText: 'Any additional notes (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.notes_outlined),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 32),

          // Next Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _currentPosition != null ? _goToCamera : null,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(
                _currentPosition != null
                    ? 'Next: Take Selfie'
                    : 'Waiting for GPS...',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusVisit,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 2: CAMERA ====================

  Widget _buildCameraStep() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _isCameraInitialized
                  ? CameraPreview(_cameraController!)
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text('Initializing camera...',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt, size: 24),
              label: const Text('Capture Selfie', style: TextStyle(fontSize: 16)),
              onPressed: _isCameraInitialized ? _takePicture : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusVisit,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== STEP 3: PREVIEW & SUBMIT ====================

  Widget _buildPreviewStep() {
    return Column(
      children: [
        // Selfie Preview
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(_capturedImage!.path),
                    fit: BoxFit.cover,
                  ),
                  // Overlay info
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black87,
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _purposeController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (_clientNameController.text.isNotEmpty)
                            Text(
                              _clientNameController.text,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.gps_fixed,
                                  size: 12, color: Colors.greenAccent),
                              const SizedBox(width: 4),
                              Text(
                                '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                    color: Colors.greenAccent, fontSize: 11),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.access_time,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('hh:mm a').format(DateTime.now()),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Retake button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _retake,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Submit Button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSubmitting ? null : _submitVisit,
              child: _isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Submitting...', style: TextStyle(fontSize: 16)),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded),
                        SizedBox(width: 8),
                        Text('Submit Visit', style: TextStyle(fontSize: 16)),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
