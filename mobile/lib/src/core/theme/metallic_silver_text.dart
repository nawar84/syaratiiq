import 'package:flutter/material.dart';

/// Metallic silver gradient text — high-contrast chrome visible on dark backgrounds.
class MetallicSilverText extends StatelessWidget {
  const MetallicSilverText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.headline = false,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool headline;

  /// Body text — visible silver (not flat white).
  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF707070),
      Color(0xFF989898),
      Color(0xFFC8C8C8),
      Color(0xFFF0F0F0),
      Color(0xFFB0B0B0),
      Color(0xFF787878),
    ],
    stops: [0.0, 0.18, 0.38, 0.48, 0.72, 1.0],
  );

  /// Hero headline — strong chrome bands.
  static const _headlineGradient = LinearGradient(
    begin: Alignment(-0.9, -1.0),
    end: Alignment(0.95, 1.0),
    colors: [
      Color(0xFF585858),
      Color(0xFF808080),
      Color(0xFFAAAAAA),
      Color(0xFFD8D8D8),
      Color(0xFFF5F5F5),
      Color(0xFFC0C0C0),
      Color(0xFF909090),
      Color(0xFF606060),
    ],
    stops: [0.0, 0.12, 0.28, 0.4, 0.48, 0.62, 0.82, 1.0],
  );

  static const inputStyle = TextStyle(color: Color(0xFFFF9412));

  static const inputDirection = TextDirection.rtl;

  static const inputAlign = TextAlign.right;

  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFFF9412), fontSize: 14),
      hintStyle: TextStyle(color: const Color(0xFFFF9412).withValues(alpha: 0.65)),
      floatingLabelStyle: inputStyle,
    );
  }

  static InputDecoration inputDecorationError(String label, String error) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFFF9412), fontSize: 14),
      errorText: error,
      errorStyle: const TextStyle(color: Color(0xFFFF8A8A), fontSize: 12),
      hintStyle: TextStyle(color: const Color(0xFFFF9412).withValues(alpha: 0.65)),
      floatingLabelStyle: inputStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = headline ? _headlineGradient : _gradient;
    final baseStyle = (style ?? const TextStyle()).copyWith(
      color: Colors.white,
      decoration: TextDecoration.none,
      shadows: const [
        Shadow(
          blurRadius: 6,
          color: Color(0x33000000),
          offset: Offset(0, 2),
        ),
        Shadow(
          blurRadius: 4,
          color: Color(0x40FFFFFF),
          offset: Offset(0, -0.5),
        ),
      ],
    );

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        final rect = bounds.isEmpty
            ? Rect.fromLTWH(0, 0, 280, (baseStyle.fontSize ?? 16) * 1.4)
            : bounds;
        return gradient.createShader(rect);
      },
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: baseStyle,
      ),
    );
  }
}

typedef AppText = MetallicSilverText;
