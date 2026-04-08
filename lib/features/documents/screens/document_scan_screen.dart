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
import '../../../l10n/app_localizations.dart';
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
    with WidgetsBindingObserver, TickerProviderStateMixin {
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

  // Animations
  late final AnimationController _scanLineController;
  late final Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Animated scan line
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _textRecognizer.close();
    _scanLineController.dispose();
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
      if (!mounted) return;
      _showError(AppLocalizations.of(context)!.capturePhotoFailed);
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _pages.length == 1
                  ? l10n.documentUploadedSuccess
                  : l10n.pagesUploadedSuccess(_pages.length),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context)!.uploadFailed);
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

  // ── Camera view with animated scanning frame overlay ────────────────────

  Widget _buildCameraView() {
    if (!_isCameraInitialized) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (!_hasCameraPermission || _cameraController == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    size: 40, color: Colors.white54),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppLocalizations.of(context)!.cameraPermissionRequired,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppLocalizations.of(context)!.cameraPermissionDesc,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: () => openAppSettings(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.openSettings),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0, duration: 400.ms),
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

        // Document edge detection frame overlay with animated scan line
        AnimatedBuilder(
          animation: _scanLineAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: _AnimatedDocumentFramePainter(
                scanProgress: _scanLineAnimation.value,
              ),
            );
          },
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
              child: Text(
                AppLocalizations.of(context)!.alignDocument,
                style: const TextStyle(
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
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                AppLocalizations.of(context)!.pageCount(_pages.length),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
                .animate()
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 300.ms, curve: Curves.elasticOut),
          ),
      ],
    );
  }

  // ── Preview after capture with smooth transition ────────────────────────

  Widget _buildPreview() {
    return Image.file(
      File(_currentCapture!.path),
      fit: BoxFit.contain,
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1), duration: 300.ms, curve: Curves.easeOut);
  }

  // ── Upload progress with premium animation ─────────────────────────────

  Widget _buildUploadProgress() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.95),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated progress ring
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: _uploadProgress > 0 ? _uploadProgress : null,
                        color: AppColors.accent,
                        strokeWidth: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    if (_uploadProgress > 0)
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      const Icon(
                        Icons.cloud_upload_outlined,
                        color: Colors.white70,
                        size: 32,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _uploadProgress > 0
                    ? AppLocalizations.of(context)!.uploadingPercent((_uploadProgress * 100).toInt())
                    : AppLocalizations.of(context)!.preparingUpload,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppLocalizations.of(context)!.pageCount(_pages.length),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0, duration: 400.ms),
        ),
      ),
    );
  }

  // ── Processing overlay with typewriter-style text ──────────────────────

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scanning animation container
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: AppColors.accentLight,
                size: 36,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.9, end: 1.1, duration: 800.ms),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context)!.readingText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Extracting text from document...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms),
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
          // Close button with press feedback
          _PremiumIconButton(
            icon: Icons.close_rounded,
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          Text(
            _phase == _ScanPhase.preview
                ? AppLocalizations.of(context)!.preview
                : _pages.isEmpty
                    ? AppLocalizations.of(context)!.scanDocument
                    : AppLocalizations.of(context)!.pageNumber(_pages.length + 1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          // Finish button (visible when pages are captured and in camera mode)
          if (_pages.isNotEmpty && _phase == _ScanPhase.camera)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentLight.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: TextButton(
                onPressed: _finishAndUpload,
                child: Text(
                  AppLocalizations.of(context)!.done,
                  style: const TextStyle(
                    color: AppColors.accentLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
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

            // Shutter button with premium animation
            _ShutterButton(
              onTap: _hasCameraPermission ? _takePhoto : _pickFromGallery,
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
      )
          .animate()
          .fadeIn(delay: 200.ms, duration: 400.ms)
          .slideY(begin: 0.15, end: 0, delay: 200.ms, duration: 400.ms),
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
                child: Text(AppLocalizations.of(context)!.retake, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                    _pages.isEmpty ? AppLocalizations.of(context)!.useThisPhoto : AppLocalizations.of(context)!.addPage,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.1, end: 0, duration: 300.ms),
    );
  }
}

// ---------------------------------------------------------------------------
// Premium Shutter Button with tap animation
// ---------------------------------------------------------------------------

class _ShutterButton extends StatefulWidget {
  const _ShutterButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: _isPressed ? 0.1 : 0.2),
                blurRadius: _isPressed ? 4 : 12,
                spreadRadius: _isPressed ? 0 : 2,
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: EdgeInsets.all(_isPressed ? 6 : 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isPressed ? Colors.white70 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Premium icon button for top bar
// ---------------------------------------------------------------------------

class _PremiumIconButton extends StatefulWidget {
  const _PremiumIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_PremiumIconButton> createState() => _PremiumIconButtonState();
}

class _PremiumIconButtonState extends State<_PremiumIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _isPressed ? Colors.white24 : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _CircleIconButton extends StatefulWidget {
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
  State<_CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<_CircleIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed!();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isActive
                ? Colors.white24
                : _isPressed
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black38,
            border: Border.all(color: Colors.white30),
          ),
          child: Icon(
            widget.icon,
            color: widget.isActive ? AppColors.accentLight : Colors.white,
            size: widget.size * 0.48,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated document frame overlay painter with scanning line
// ---------------------------------------------------------------------------

class _AnimatedDocumentFramePainter extends CustomPainter {
  _AnimatedDocumentFramePainter({required this.scanProgress});

  final double scanProgress;

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

    // Draw animated scanning line
    final scanY = frameRect.top + (frameRect.height * scanProgress);
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF0D9488).withValues(alpha: 0.6),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(frameRect.left, scanY - 1, frameRect.width, 2));
    canvas.drawRect(
      Rect.fromLTWH(frameRect.left + 4, scanY - 1, frameRect.width - 8, 2),
      scanLinePaint,
    );

    // Draw corner brackets (white with glow effect)
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
  bool shouldRepaint(covariant _AnimatedDocumentFramePainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress;
  }
}
