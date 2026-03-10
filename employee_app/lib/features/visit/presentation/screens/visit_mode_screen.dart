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

class VisitModeScreen extends ConsumerStatefulWidget {
  const VisitModeScreen({super.key});
  @override
  ConsumerState<VisitModeScreen> createState() => _VisitModeScreenState();
}

class _VisitModeScreenState extends ConsumerState<VisitModeScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCheckingIn = false;
  Position? _currentPosition;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initCamera();
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
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy
            .best, // Not available directly without setting, but high is good
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) _showError('GPS Error', e.toString());
    }
  }

  void _showError(String title, String message) {
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
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    if (_currentPosition == null) {
      _showError('Location Required', 'GPS signal not acquired yet.');
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      setState(() => _capturedImage = image);
    } catch (e) {
      _showError('Camera Error', 'Failed to take selfie');
    }
  }

  void _retake() {
    setState(() => _capturedImage = null);
  }

  Future<void> _submitVisit() async {
    if (_capturedImage == null || _currentPosition == null) return;
    final auth = ref.read(authProvider);
    final employeeId = auth.user?.employeeId;
    if (employeeId == null) return;

    setState(() => _isCheckingIn = true);

    try {
      final appwrite = AppwriteService.instance;

      // 1. Upload Selfie
      final fileName =
          '$employeeId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRes = await appwrite.storage.createFile(
        bucketId: AppwriteConfig.visitSelfiesBucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(
          path: _capturedImage!.path,
          filename: fileName,
        ),
      );

      final selfieUrl =
          '${AppwriteConfig.endpoint}/storage/buckets/${AppwriteConfig.visitSelfiesBucketId}/files/${storageRes.$id}/view?project=${AppwriteConfig.projectId}';

      // 2. Add Attendance Record
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final nowIso = DateTime.now().toIso8601String();

      await appwrite.databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.attendanceCollectionId,
        documentId: ID.unique(),
        data: {
          'employeeId': employeeId,
          'employeeCode': '', // HR system handles missing codes usually
          'date': today,
          'status': 'visit',
          'checkIn': nowIso,
          'location':
              '${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
          'selfieId': storageRes.$id,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit marked successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) _showError('Submission Failed', e.toString());
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Mode Check-In'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Strip
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              color: AppColors.statusVisit.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    _currentPosition != null
                        ? Icons.gps_fixed
                        : Icons.gps_not_fixed,
                    color: _currentPosition != null
                        ? AppColors.statusVisit
                        : AppColors.error,
                    size: 18,
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
                ],
              ),
            ),

            // Camera / Preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  // overflow: Overflow.hidden
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _capturedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(_capturedImage!.path),
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                ),
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                ),
                                onPressed: _retake,
                              ),
                            ),
                          ],
                        )
                      : _isCameraInitialized
                      ? CameraPreview(_cameraController!)
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                ),
              ),
            ),

            // Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: _capturedImage == null
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Capture Selfie'),
                        onPressed:
                            (_isCameraInitialized && _currentPosition != null)
                            ? _takePicture
                            : null,
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusVisit,
                        ),
                        onPressed: _isCheckingIn ? null : _submitVisit,
                        child: _isCheckingIn
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Submit Visit Check-In',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
