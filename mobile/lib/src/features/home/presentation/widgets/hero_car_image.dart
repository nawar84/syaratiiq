import 'package:flutter/material.dart';

class HeroCarImage extends StatelessWidget {
  const HeroCarImage({super.key, required this.scale});

  final double scale;

  static const _asset = 'assets/images/hero_toyota_land_cruiser.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230 * scale,
      width: double.infinity,
      child: Image.asset(
        _asset,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
