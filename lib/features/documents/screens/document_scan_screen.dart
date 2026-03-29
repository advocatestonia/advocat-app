import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../config/theme.dart';
import '../../../services/supabase_service.dart';

// ---------------------------------------------------------------------------
// Scan state machine
// ---------------------------------------------------------------------------

enum _ScanPhase { camera, preview, uploading }

/// Page in a multi-page scan.
class _ScannedPage {
  final XFile file;
  final String? ocrText;

  const _ScannedPage({required this.file, this.ocrText});
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DocumentScanScreen extends ConsumerStatefulWidget {
  const DocumentScanScreen({super.key, this.caseId});

  /// If provided, the scanned document is uploaded directly to this case.
  final String? caseId;

  @override
  ConsumerState<DocumentScanScreen> createState() => _DocumentScanScreenState();
}

class _DocumentScanScreenState extends ConsumerState<DocumentScanScreen>
    with WidgetsBindingObserver {
  // Camera
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _hasCameraPermission = false;

  // Image picker fallback
  final _picker = ImagePicker();

  // OCR
  final _textRecognizer = TextRecognizer();

  // State
  _ScanPhase _phase = _ScanPhase.camera;
  XFile? _currentCapture;
  final List<_ScannedPage> _pages = [];
  bool _isProcessingOcr = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // ── Camera init ──────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() {
          _hasCameraPermission = false;
          _isCameraInitialized = true;
        });
      }
      return;
    }

    setState(() => _hasCameraPermission = true);

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      HapticFeedback.mediumImpact();
      final xFile = await _cameraController!.takePicture();
      setState(() {
        _currentCapture = xFile;
        _phase = _ScanPhase.preview;
      });
    } catch (_) {
      _showError('Failed to capture photo. Please try again.');
    }
  }

  Future<void> _pickFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (image != null && mounted) {
      setState(() {
        _currentCapture = image;
        _phase = _ScanPhase.preview;
      });
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    try {
      final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(newMode);
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (_) {}
  }

  void _retake() {
    setState(() {
      _currentCapture = null;
      _phase = _ScanPhase.camera;
    });
  }

  Future<void> _usePhoto() async {
    if (_currentCapture == null) return;

    setState(() => _isProcessingOcr = true);

    String? ocrText;
    try {
      final inputImage = InputImage.fromFilePath(_currentCapture!.path);
      final recognized = await _textRecognizer.processImage(inputImage);
      ocrText = recognized.text;
    } catch (_) {
      // OCR failure is non-fatal; we still keep the page.
    }

    setState(() {
      _pages.add(_ScannedPage(file: _currentCapture!, ocrText: ocrText));
      _currentCapture = null;
      _phase = _ScanPhase.camera;
      _isProcessingOcr = false;
    });
  }

  Future<void> _finishAndUpload() async {
    if (_pages.isEmpty) return;

    setState(() {
      _phase = _ScanPhase.uploading;
      _uploadProgress = 0;
    });

    try {
      final supabase = ref.read(supabaseServiceProvider);
      final caseId = widget.caseId;

      if (caseId == null) {
        // No case context — just pop with results.
        if (mounted) context.pop(_pages);
        return;
      }

      for (var i = 0; i < _pages.length; i++) {
        final page = _pages[i];
        final bytes = await File(page.file.path).readAsBytes();
        final fileName =
            'scan_${DateTime.now().millisecondsSinceEpoch}_p${i + 1}.jpg';

        await supabase.uploadDocument(
          caseId: caseId,
          fileName: fileName,
          fileBytes: bytes,
          mimeType: 'image/jpeg',
        );

        if (mounted) {
          setState(() => _uploadProgress = (i + 1) / _pages.length);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _pages.length == 1
                  ? 'Document uploaded successfully'
                  : '${_pages.length} pages uploaded successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      _showError('Upload failed. Please check your connection and try again.');
      setState(() => _phase = _ScanPhase.camera);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1 — camera / preview / upload
          if (_phase == _ScanPhase.camera) _buildCameraView(),
          if (_phase == _ScanPhase.preview) _buildPreview(),
          if (_phase == _ScanPhase.uploading) _buildUploadProgress(),

          // Layer 2 — top bar (safe area)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // Layer 3 — bottom controls
          if (_phase == _ScanPhase.camera) _buildCameraControls(),
          if (_phase == _ScanPhase.preview) _buildPreviewControls(),

          // Layer 4 — OCR processing overlay
          if (_isProcessingOcr) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  // ── Camera view with document frame overlay ─────────────────────────────

  Widget _buildCameraView() {
    if (!_isCameraInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (!_hasCameraPermission || _cameraController == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined,
                  size: 64, color: Colors.white54),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Camera permission required',
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Grant camera access to scan documents, or use the gallery.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: () => openAppSettings(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _cameraController!.value.previewSize?.height ?? 1920,
                height: _cameraController!.value.previewSize?.width ?? 1080,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),
        ),

        // Document edge detection frame overlay
        CustomPaint(
          painter: _DocumentFramePainter(),
        ),

        // Hint text
        Positioned(
          bottom: 160,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Align document within the frame',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 1200.ms)
              .then()
              .fadeOut(duration: 1200.ms),
        ),

        // Page counter badge
        if (_pages.isNotEmpty)
          Positioned(
            bottom: 170,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_pages.length} page${_pages.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Preview after capture ───────────────────────────────────────────────

  Widget _buildPreview() {
    return Image.file(
      File(_currentCapture!.path),
      fit: BoxFit.contain,
    );
  }

  // ── Upload progress ─────────────────────────────────────────────────────

  Widget _buildUploadProgress() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.95),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  color: AppColors.accent,
                  strokeWidth: 4,
                  backgroundColor: Colors.white24,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _uploadProgress > 0
                    ? 'Uploading... ${(_uploadProgress * 100).toInt()}%'
                    : 'Preparing upload...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${_pages.length} page${_pages.length > 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Processing overlay ──────────────────────────────────────────────────

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: AppSpacing.md),
            Text(
              'Reading text...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 8,
        bottom: 8,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          ),
          const Spacer(),
          Text(
            _phase == _ScanPhase.preview
                ? 'Preview'
                : _pages.isEmpty
                    ? 'Scan Document'
                    : 'Page ${_pages.length + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Finish button (visible when pages are captured and in camera mode)
          if (_pages.isNotEmpty && _phase == _ScanPhase.camera)
            TextButton(
              onPressed: _finishAndUpload,
              child: const Text(
                'Done',
                style: TextStyle(
                  color: AppColors.accentLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Camera bottom controls ──────────────────────────────────────────────

  Widget _buildCameraControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Gallery
            _CircleIconButton(
              icon: Icons.photo_library_outlined,
              onPressed: _pickFromGallery,
              size: 48,
            ),

            // Shutter button
            GestureDetector(
              onTap: _hasCameraPermission ? _takePhoto : _pickFromGallery,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Flash toggle
            _CircleIconButton(
              icon: _isFlashOn
                  ? Icons.flash_on_rounded
                  : Icons.flash_off_rounded,
              onPressed: _hasCameraPermission ? _toggleFlash : null,
              size: 48,
              isActive: _isFlashOn,
            ),
          ],
        ),
      ),
    );
  }

  // ── Preview bottom controls ─────────────────────────────────────────────

  Widget _buildPreviewControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _retake,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                child: const Text('Retake', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isProcessingOcr ? null : _usePhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                child: Text(
                  _pages.isEmpty ? 'Use This Photo' : 'Add Page',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.white24 : Colors.black38,
          border: Border.all(color: Colors.white30),
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.accentLight : Colors.white,
          size: size * 0.48,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Document frame overlay painter
// ---------------------------------------------------------------------------

class _DocumentFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent overlay outside the frame
    final frameRect = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.15,
      size.width * 0.84,
      size.height * 0.55,
    );

    // Draw darkened area outside the frame
    final outerPath = Path()..addRect(Offset.zero & size);
    final innerPath = Path()
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(12)));
    final overlayPath =
        Path.combine(PathOperation.difference, outerPath, innerPath);

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // Draw corner brackets (white)
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 28.0;
    const r = 12.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(frameRect.left, frameRect.top + cornerLen)
        ..lineTo(frameRect.left, frameRect.top + r)
        ..quadraticBezierTo(
            frameRect.left, frameRect.top, frameRect.left + r, frameRect.top)
        ..lineTo(frameRect.left + cornerLen, frameRect.top),
      cornerPaint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(frameRect.right - cornerLen, frameRect.top)
        ..lineTo(frameRect.right - r, frameRect.top)
        ..quadraticBezierTo(
            frameRect.right, frameRect.top, frameRect.right, frameRect.top + r)
        ..lineTo(frameRect.right, frameRect.top + cornerLen),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(frameRect.left, frameRect.bottom - cornerLen)
        ..lineTo(frameRect.left, frameRect.bottom - r)
        ..quadraticBezierTo(frameRect.left, frameRect.bottom,
            frameRect.left + r, frameRect.bottom)
        ..lineTo(frameRect.left + cornerLen, frameRect.bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(frameRect.right - cornerLen, frameRect.bottom)
        ..lineTo(frameRect.right - r, frameRect.bottom)
        ..quadraticBezierTo(frameRect.right, frameRect.bottom, frameRect.right,
            frameRect.bottom - r)
        ..lineTo(frameRect.right, frameRect.bottom - cornerLen),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
