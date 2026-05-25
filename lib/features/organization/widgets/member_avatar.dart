import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// Circular avatar with image URL fallback to coloured-letter initial.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.initial,
    this.imageUrl,
    this.size = 36,
  });

  final String initial;
  final String? imageUrl;
  final double size;

  /// Stable colour derived from the initial so the same person looks the
  /// same colour across screens.
  Color get _bgColor {
    final hash = initial.codeUnits.fold<int>(0, (a, b) => a + b);
    const palette = [
      Color(0xFFE0F2FE), // blue-50
      Color(0xFFFCE7F3), // pink-50
      Color(0xFFD1FAE5), // green-50
      Color(0xFFFEF3C7), // amber-50
      Color(0xFFEDE9FE), // violet-50
      Color(0xFFFEE2E2), // red-50
    ];
    return palette[hash % palette.length];
  }

  Color get _fgColor {
    final hash = initial.codeUnits.fold<int>(0, (a, b) => a + b);
    const palette = [
      Color(0xFF075985),
      Color(0xFF9D174D),
      Color(0xFF065F46),
      Color(0xFF92400E),
      Color(0xFF5B21B6),
      Color(0xFF991B1B),
    ];
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasImage ? AppColors.surfaceVariant : _bgColor,
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
                onError: (_, __) {},
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasImage
          ? null
          : Text(
              initial,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: size * 0.42,
                color: _fgColor,
              ),
            ),
    );
  }
}
