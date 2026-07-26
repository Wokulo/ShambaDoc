import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shambadoc/ai/tflite_service.dart';
import 'package:shambadoc/ai/cloud_ai_service.dart';
import 'package:shambadoc/ai/disease_model.dart';
import 'package:shambadoc/services/storage_service.dart';
import 'package:shambadoc/app/routes.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _camera;
  bool _isReady = false;
  bool _isProcessing = false;
  FlashMode _flashMode = FlashMode.off;

  late final AnimationController _pulseCtrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);
  late final Animation<double> _pulse = Tween(begin: 0.97, end: 1.03)
      .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    if (!Platform.isLinux) _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) _showPermissionDialog();
      return;
    }
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _camera = CameraController(cameras.first, ResolutionPreset.high,
        enableAudio: false);
    await _camera!.initialize();
    await TFLiteService().init();
    if (mounted) setState(() => _isReady = true);
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Camera Permission Required'),
        content: const Text(
            'ShambaDoc needs camera access to scan your crops. Please enable it in Settings.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: openAppSettings,
              child: const Text('Open Settings')),
        ],
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (_camera == null) return;
    final next =
        _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _camera!.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    await _processImage(File(picked.path));
  }

  Future<void> _takePhoto() async {
    if (_camera == null ||
        !_camera!.value.isInitialized ||
        _isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final photo = await _camera!.takePicture();
      await _processImage(File(photo.path));
    } catch (e) {
      _showError('Failed to capture photo. Please try again.');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processImage(File imageFile) async {
    if (mounted) setState(() => _isProcessing = true);
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.medium)
            .timeout(const Duration(seconds: 5));
      } catch (_) {}

      final tfResult = await TFLiteService().predict(imageFile);
      DiseaseModel finalResult = tfResult;

      if (tfResult.confidence < 0.75) {
        final connectivity = await Connectivity().checkConnectivity();
        if (connectivity != ConnectivityResult.none) {
          final cloudResult = await CloudAIService.cloudPredict(imageFile);
          if (cloudResult != null &&
              cloudResult.confidence > tfResult.confidence) {
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
      _showError('Analysis failed. Please retake the photo in better light.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _camera?.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text('Initializing camera…',
                style: TextStyle(color: Colors.white.withOpacity(0.7))),
          ]),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final frameSize = size.width * 0.68;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        // Camera preview
        CameraPreview(_camera!),

        // Vignette
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
            ),
          ),
        ),

        // Scan frame
        Center(
          child: ScaleTransition(
            scale: _pulse,
            child: SizedBox(
              width: frameSize,
              height: frameSize,
              child: Stack(children: [
                // Dimmed outside hint
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.6), width: 2),
                    ),
                  ),
                ),
                // Accent corners
                ..._corners(frameSize),
                // Label
                if (!_isProcessing)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Center affected leaf here',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white,
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ]),
            ),
          ),
        ),

        // Processing overlay
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.55),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(
                  width: 56, height: 56,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3),
                ),
                const SizedBox(height: 20),
                const Text('Analyzing crop…',
                  style: TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('This may take a few seconds',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.65), fontSize: 13)),
              ]),
            ),
          ),

        // Top bar
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _IconBtn(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context)),
                  const Text('Scan Crop',
                    style: TextStyle(color: Colors.white,
                        fontSize: 17, fontWeight: FontWeight.w700)),
                  _IconBtn(
                    icon: _flashMode == FlashMode.off
                        ? Icons.flash_off_rounded
                        : Icons.flash_on_rounded,
                    onTap: _toggleFlash,
                    active: _flashMode == FlashMode.torch,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom controls
        if (!_isProcessing)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 16, 40, 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _IconBtn(
                        icon: Icons.photo_library_outlined,
                        onTap: _pickFromGallery,
                        size: 52,
                        tooltip: 'Gallery'),
                    // Shutter
                    GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        width: 78, height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.white.withOpacity(0.18),
                        ),
                        child: const Icon(Icons.camera_rounded,
                            color: Colors.white, size: 38),
                      ),
                    ),
                    const SizedBox(width: 52),
                  ],
                ),
              ),
            ),
          ),
      ]),
    );
  }

  List<Widget> _corners(double frameSize) {
    const s = 26.0;
    const t = 3.5;
    const c = AppColors.accentLight;
    return [
      Positioned(top: 0, left: 0,
          child: _Corner(size: s, thickness: t, color: c, top: true, left: true)),
      Positioned(top: 0, right: 0,
          child: _Corner(size: s, thickness: t, color: c, top: true, left: false)),
      Positioned(bottom: 0, left: 0,
          child: _Corner(size: s, thickness: t, color: c, top: false, left: true)),
      Positioned(bottom: 0, right: 0,
          child: _Corner(size: s, thickness: t, color: c, top: false, left: false)),
    ];
  }
}

class _Corner extends StatelessWidget {
  final double size, thickness;
  final Color color;
  final bool top, left;
  const _Corner(
      {required this.size, required this.thickness,
        required this.color, required this.top, required this.left});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: CustomPaint(
        painter: _CornerPainter(color, thickness, top, left)),
  );
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double t;
  final bool top, left;
  _CornerPainter(this.color, this.t, this.top, this.left);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = t
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    if (top && left) {
      path.moveTo(0, s.height); path.lineTo(0, 0); path.lineTo(s.width, 0);
    } else if (top) {
      path.moveTo(0, 0); path.lineTo(s.width, 0); path.lineTo(s.width, s.height);
    } else if (left) {
      path.moveTo(0, 0); path.lineTo(0, s.height); path.lineTo(s.width, s.height);
    } else {
      path.moveTo(0, s.height); path.lineTo(s.width, s.height); path.lineTo(s.width, 0);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final double size;
  final String? tooltip;
  const _IconBtn({required this.icon, required this.onTap,
    this.active = false, this.size = 46, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? AppColors.accentLight.withOpacity(0.3)
              : Colors.black.withOpacity(0.42),
        ),
        child: Icon(icon,
            color: active ? AppColors.accentLight : Colors.white,
            size: size * 0.48),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}
