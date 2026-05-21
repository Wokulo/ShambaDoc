import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shambadoc/ai/tflite_service.dart';
import 'package:shambadoc/ai/cloud_ai_service.dart';
import 'package:shambadoc/ai/disease_model.dart';
import 'package:shambadoc/services/storage_service.dart';
import 'package:shambadoc/app/routes.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isReady = false;
  bool _isProcessing = false;
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    _cameraController = CameraController(
      _cameras!.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    await TFLiteService().init();

    if (mounted) setState(() => _isReady = true);
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);
      setState(() => _capturedImage = imageFile);

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      } catch (e) {
        print('Location error: $e');
      }

      final tfResult = await TFLiteService().predict(imageFile);
      DiseaseModel finalResult = tfResult;

      if (tfResult.confidence < 0.75) {
        final connectivity = await Connectivity().checkConnectivity();
        if (connectivity != ConnectivityResult.none) {
          final cloudResult = await CloudAIService.cloudPredict(imageFile);
          if (cloudResult != null && cloudResult.confidence > tfResult.confidence) {
            finalResult = cloudResult;
          }
        }
      }

      final scan = ScanResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: imageFile.path,
        disease: finalResult,
        timestamp: DateTime.now(),
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      await StorageService().saveScan(scan);

      CloudAIService.logScan({
        'scan_id': scan.id,
        'disease': finalResult.name,
        'confidence': finalResult.confidence,
        'confidence_tier': finalResult.confidenceTier,
        'severity': finalResult.severity,
        'crop_type': finalResult.cropType,
        'lat': position?.latitude,
        'lng': position?.longitude,
        'timestamp': scan.timestamp.toIso8601String(),
      });

      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.result,
          arguments: {'scan': scan, 'image': imageFile});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          Center(
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('Center affected leaf here',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            ),
          ),
          Positioned(
            top: 40, left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Column(
              children: [
                if (_isProcessing)
                  const Column(children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text('Analyzing...', style: TextStyle(color: Colors.white)),
                  ])
                else
                  GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.white24,
                      ),
                      child: const Icon(Icons.camera, color: Colors.white, size: 32),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
