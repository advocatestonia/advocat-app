import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme.dart';

// ---------------------------------------------------------------------------
// Voice button states
// ---------------------------------------------------------------------------

enum VoiceButtonState {
  /// Idle — gray mic, ready to tap
  idle,

  /// Listening — pulsing red mic, recording user speech
  listening,

  /// Processing — spinner, sending to AI
  processing,

  /// Speaking — animated wave, AI reading response
  speaking,
}

// ---------------------------------------------------------------------------
// Voice Button Widget
// ---------------------------------------------------------------------------

class VoiceButton extends StatefulWidget {
  const VoiceButton({
    super.key,
    required this.state,
    required this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.partialText,
    this.size = 56,
  });

  final VoiceButtonState state;
  final VoidCallback onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  /// Partial speech-to-text result to display near the button.
  final String? partialText;

  /// Diameter of the button.
  final double size;

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didUpdateWidget(VoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimations();
  }

  void _syncAnimations() {
    // Pulse for listening state
    if (widget.state == VoiceButtonState.listening) {
      if (!_pulseController.isAnimating) _pulseController.repeat();
    } else {
      _pulseController.reset();
    }

    // Wave for speaking state
    if (widget.state == VoiceButtonState.speaking) {
      if (!_waveController.isAnimating) _waveController.repeat();
    } else {
      _waveController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  // ── Colors ──────────────────────────────────────────────────────────────

  static const _navy = Color(0xFF1A2B4A);
  static const _teal = Color(0xFF0D9488);
  static const _red = Color(0xFFDC2626);

  Color get _buttonColor {
    switch (widget.state) {
      case VoiceButtonState.idle:
        return _navy;
      case VoiceButtonState.listening:
        return _red;
      case VoiceButtonState.processing:
        return _teal;
      case VoiceButtonState.speaking:
        return _teal;
    }
  }

  Color get _glowColor {
    switch (widget.state) {
      case VoiceButtonState.idle:
        return _navy.withValues(alpha: 0.2);
      case VoiceButtonState.listening:
        return _red.withValues(alpha: 0.35);
      case VoiceButtonState.processing:
        return _teal.withValues(alpha: 0.25);
      case VoiceButtonState.speaking:
        return _teal.withValues(alpha: 0.3);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _syncAnimations();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Partial text preview
        if (widget.partialText != null && widget.partialText!.isNotEmpty)
          _buildPartialText(),

        // The button itself
        SizedBox(
          width: widget.size + 24,
          height: widget.size + 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring (listening state)
              if (widget.state == VoiceButtonState.listening)
                _buildPulseRing(),

              // Sound wave rings (speaking state)
              if (widget.state == VoiceButtonState.speaking)
                _buildSoundWaves(),

              // Main button
              _buildMainButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartialText() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        widget.partialText!,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildPulseRing() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.4);
        final opacity = 1.0 - _pulseController.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _red.withValues(alpha: opacity * 0.6),
                width: 3,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSoundWaves() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size + 24, widget.size + 24),
          painter: _SoundWavePainter(
            progress: _waveController.value,
            color: _teal,
          ),
        );
      },
    );
  }

  Widget _buildMainButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onLongPressStart: widget.onLongPressStart != null
          ? (_) {
              HapticFeedback.heavyImpact();
              widget.onLongPressStart!();
            }
          : null,
      onLongPressEnd: widget.onLongPressEnd != null
          ? (_) {
              HapticFeedback.lightImpact();
              widget.onLongPressEnd!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _buttonColor,
              Color.lerp(_buttonColor, Colors.black, 0.15)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _glowColor,
              blurRadius: widget.state == VoiceButtonState.listening ? 20 : 12,
              spreadRadius:
                  widget.state == VoiceButtonState.listening ? 4 : 1,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: _buttonColor.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    switch (widget.state) {
      case VoiceButtonState.idle:
        return const Icon(
          Icons.mic_rounded,
          color: Colors.white,
          size: 26,
        );

      case VoiceButtonState.listening:
        return Icon(
          Icons.mic_rounded,
          color: Colors.white.withValues(alpha: 0.95),
          size: 26,
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
              begin: 0.9,
              end: 1.15,
              duration: 600.ms,
              curve: Curves.easeInOut,
            );

      case VoiceButtonState.processing:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        );

      case VoiceButtonState.speaking:
        return AnimatedBuilder(
          animation: _waveController,
          builder: (context, _) {
            return CustomPaint(
              size: const Size(28, 28),
              painter: _SpeakerBarsPainter(
                progress: _waveController.value,
                color: Colors.white,
              ),
            );
          },
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Custom painters
// ---------------------------------------------------------------------------

/// Paints concentric expanding rings for the speaking state.
class _SoundWavePainter extends CustomPainter {
  _SoundWavePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + i * 0.33) % 1.0;
      final radius = maxRadius * 0.5 + (maxRadius * 0.5 * waveProgress);
      final opacity = (1.0 - waveProgress) * 0.35;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SoundWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Paints animated equalizer bars inside the button (speaking state icon).
class _SpeakerBarsPainter extends CustomPainter {
  _SpeakerBarsPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const barCount = 5;
    final barWidth = size.width / (barCount * 2 - 1);
    final maxHeight = size.height * 0.8;

    for (int i = 0; i < barCount; i++) {
      // Each bar oscillates at a different phase
      final phase = (progress * 2 * math.pi) + (i * math.pi / barCount * 1.5);
      final heightFactor = 0.25 + 0.75 * ((math.sin(phase) + 1) / 2);
      final barHeight = maxHeight * heightFactor;

      final x = i * barWidth * 2;
      final y = (size.height - barHeight) / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_SpeakerBarsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
