import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../../core/models/transaction_model.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/receipt_parser.dart';
import '../transactions/review_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  bool _hasPermission = false;
  final OcrService _ocrService = OcrService();
  final ImagePicker _picker = ImagePicker();

  // Tap-to-focus indicator
  Offset? _focusPoint;
  late final AnimationController _focusAnimController;
  late final Animation<double> _focusScaleAnim;
  late final Animation<double> _focusOpacityAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _focusScaleAnim = Tween<double>(begin: 1.4, end: 1.0).animate(
      CurvedAnimation(parent: _focusAnimController, curve: Curves.easeOut),
    );
    _focusOpacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _focusAnimController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );
    _requestPermissionAndInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusAnimController.dispose();
    _controller?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras != null && _cameras!.isNotEmpty) {
        _initCamera(_cameras!.first);
      }
    }
  }

  Future<void> _requestPermissionAndInit() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        await _initCamera(_cameras!.first);
      }
    } else {
      setState(() => _hasPermission = false);
    }
  }

  Future<void> _initCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    setState(() => _isFlashOn = !_isFlashOn);
    try {
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (_) {}
  }

  Future<void> _onTapToFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final touchX = details.localPosition.dx;
    final touchY = details.localPosition.dy;

    setState(() {
      _focusPoint = Offset(touchX, touchY);
    });

    _focusAnimController.reset();
    _focusAnimController.forward();

    // Convert to normalized coordinates (0.0 to 1.0) for CameraController
    final nx = (touchX / constraints.maxWidth).clamp(0.0, 1.0);
    final ny = (touchY / constraints.maxHeight).clamp(0.0, 1.0);

    try {
      await _controller!.setFocusPoint(Offset(nx, ny));
      await _controller!.setExposurePoint(Offset(nx, ny));
    } catch (e) {
      debugPrint('Focus tap error: $e');
    }
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final xFile = await _controller!.takePicture();
      await _processImageFile(xFile.path, shouldCropToFrame: true);
    } catch (e) {
      if (mounted) {
        _dismissDialog();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _isCapturing = true);
        await _processImageFile(picked.path, shouldCropToFrame: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _processImageFile(String sourcePath, {required bool shouldCropToFrame}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(path.join(appDir.path, 'receipts'));
    await receiptsDir.create(recursive: true);

    final fileId = const Uuid().v4();
    final savedPath = path.join(receiptsDir.path, '$fileId.jpg');

    if (!mounted) return;
    _showProcessingDialog('Optimizing and cropping image...');

    // Perform cropping on background isolate if cropping is desired
    if (shouldCropToFrame) {
      try {
        final bytes = await File(sourcePath).readAsBytes();
        final croppedBytes = await compute(_cropImageIsolate, bytes);
        if (croppedBytes != null) {
          await File(savedPath).writeAsBytes(croppedBytes);
        } else {
          await File(sourcePath).copy(savedPath);
        }
      } catch (_) {
        await File(sourcePath).copy(savedPath);
      }
    } else {
      await File(sourcePath).copy(savedPath);
    }

    if (!mounted) return;
    _dismissDialog();
    _showProcessingDialog('Extracting text with on-device ML Kit...');

    final rawText = await _ocrService.extractText(savedPath);
    final parsed = ReceiptParser.parse(rawText);

    if (!mounted) return;
    _dismissDialog();

    final result = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          imagePath: savedPath,
          parsedReceipt: parsed,
          rawOcrText: rawText,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  void _showProcessingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text(
              '(On-device ML Kit, sub-100ms offline)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _dismissDialog() {
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _hasPermission ? _buildCameraView() : _buildPermissionDenied(),
    );
  }

  Widget _buildCameraView() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Camera viewfinder with tap-to-focus gesture
            GestureDetector(
              onTapDown: (details) => _onTapToFocus(details, constraints),
              child: CameraPreview(_controller!),
            ),

            // Visual tap-to-focus ring
            if (_focusPoint != null)
              AnimatedBuilder(
                animation: _focusAnimController,
                builder: (context, child) {
                  return Positioned(
                    left: _focusPoint!.dx - 32,
                    top: _focusPoint!.dy - 32,
                    child: Opacity(
                      opacity: _focusOpacityAnim.value,
                      child: Transform.scale(
                        scale: _focusScaleAnim.value,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.amberAccent, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.center_focus_weak, color: Colors.amberAccent, size: 28),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Framing crop overlay
            CustomPaint(painter: _CropOverlayPainter()),

            // Top action bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      Row(
                        children: [
                          _CircleButton(
                            icon: Icons.photo_library,
                            onTap: _pickFromGallery,
                          ),
                          const SizedBox(width: 12),
                          _CircleButton(
                            icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            onTap: _toggleFlash,
                            color: _isFlashOn ? Colors.yellow : Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Guidance hint badge
            const Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: Center(
                child: _HintBadge('Tap to focus • Frame receipt inside box'),
              ),
            ),

            // Bottom capture button and gallery shortcut
            Positioned(
              bottom: 44,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _captureAndProcess,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _isCapturing ? 60 : 76,
                    height: _isCapturing ? 60 : 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: _isCapturing
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : const Icon(Icons.camera_alt, size: 36, color: Colors.black87),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              'Camera permission required',
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const ElevatedButton(
              onPressed: openAppSettings,
              child: Text('Open Settings'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick from Gallery instead'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Isolate function to crop image to the framing rectangle area
Uint8List? _cropImageIsolate(Uint8List imageBytes) {
  final decoded = img.decodeImage(imageBytes);
  if (decoded == null) return null;

  // Relative crop frame: top 15%, bottom 78%, left/right 6% margin
  final cropX = (decoded.width * 0.06).toInt();
  final cropY = (decoded.height * 0.15).toInt();
  final cropW = (decoded.width * 0.88).toInt();
  final cropH = (decoded.height * 0.63).toInt();

  final cropped = img.copyCrop(
    decoded,
    x: cropX.clamp(0, decoded.width - 1),
    y: cropY.clamp(0, decoded.height - 1),
    width: cropW.clamp(1, decoded.width - cropX),
    height: cropH.clamp(1, decoded.height - cropY),
  );

  return Uint8List.fromList(img.encodeJpg(cropped, quality: 90));
}

// ─── Helpers ──────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.45),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _HintBadge extends StatelessWidget {
  final String text;
  const _HintBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}

// ─── Crop Overlay Painter ─────────────────────────────────────────────────

class _CropOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const margin = 24.0;
    final rectTop = size.height * 0.15;
    final rectBottom = size.height * 0.78;
    final cropRect = Rect.fromLTRB(margin, rectTop, size.width - margin, rectBottom);

    // Dimmed translucent outer overlay with clear cutout for receipt
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.52)
      ..style = PaintingStyle.fill;
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cropRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, overlayPaint);

    // Subtle framing border
    canvas.drawRRect(
      RRect.fromRectAndRadius(cropRect, const Radius.circular(16)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // High-visibility corner framing accents
    const cLen = 30.0;
    final cp = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final l = cropRect.left;
    final t = cropRect.top;
    final r = cropRect.right;
    final b = cropRect.bottom;

    // Top-Left
    canvas.drawLine(Offset(l, t + cLen), Offset(l, t + 4), cp);
    canvas.drawLine(Offset(l + 4, t), Offset(l + cLen, t), cp);
    // Top-Right
    canvas.drawLine(Offset(r - cLen, t), Offset(r - 4, t), cp);
    canvas.drawLine(Offset(r, t + 4), Offset(r, t + cLen), cp);
    // Bottom-Left
    canvas.drawLine(Offset(l, b - cLen), Offset(l, b - 4), cp);
    canvas.drawLine(Offset(l + 4, b), Offset(l + cLen, b), cp);
    // Bottom-Right
    canvas.drawLine(Offset(r - cLen, b), Offset(r - 4, b), cp);
    canvas.drawLine(Offset(r, b - 4), Offset(r, b - cLen), cp);
  }

  @override
  bool shouldRepaint(_) => false;
}
