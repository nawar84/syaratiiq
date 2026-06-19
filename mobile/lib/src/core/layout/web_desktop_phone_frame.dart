import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// On Flutter Web desktop, centers the app inside a phone preview frame.
/// Below [breakpoint] width the child is returned unchanged.
class WebDesktopPhoneFrame extends StatelessWidget {
  const WebDesktopPhoneFrame({
    super.key,
    required this.child,
    this.breakpoint = 600,
    this.screenWidth = 420,
    this.bezelWidth = 12,
    this.outerRadius = 44,
    this.innerRadius = 32,
  });

  final Widget child;
  final double breakpoint;
  final double screenWidth;
  final double bezelWidth;
  final double outerRadius;
  final double innerRadius;

  static const _backgroundTop = Color(0xFF061338);
  static const _backgroundBottom = Color(0xFF030B24);
  static const _bezelColor = Color(0xFF0A0A0A);

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    final viewport = MediaQuery.sizeOf(context);
    if (viewport.width <= breakpoint) return child;

    const aspectRatio = 9 / 19.5;
    final outerWidth = screenWidth + bezelWidth * 2;
    final maxOuterHeight = viewport.height * 0.92;
    var outerHeight = outerWidth / aspectRatio;
    if (outerHeight > maxOuterHeight) {
      outerHeight = maxOuterHeight;
    }
    final screenHeight = outerHeight - bezelWidth * 2;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_backgroundTop, _backgroundBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Container(
            width: outerWidth,
            height: outerHeight,
            decoration: BoxDecoration(
              color: _bezelColor,
              borderRadius: BorderRadius.circular(outerRadius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 48,
                  offset: Offset(0, 24),
                ),
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: EdgeInsets.all(bezelWidth),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(innerRadius),
              child: SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(screenWidth, screenHeight),
                    padding: EdgeInsets.zero,
                    viewPadding: EdgeInsets.zero,
                    viewInsets: EdgeInsets.zero,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
