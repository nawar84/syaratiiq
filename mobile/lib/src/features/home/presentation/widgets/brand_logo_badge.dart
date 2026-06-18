import 'package:flutter/material.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';

class BrandLogoBadge extends StatelessWidget {
  const BrandLogoBadge({
    super.key,
    required this.brand,
    required this.scale,
  });

  final BrandEntity brand;
  final double scale;

  static const _pngAssetByName = {
    'toyota': 'assets/brands/png/toyota.png',
    'hyundai': 'assets/brands/png/hyundai.png',
    'bmw': 'assets/brands/png/bmw.png',
    'mercedes': 'assets/brands/png/mercedes.png',
    'kia': 'assets/brands/png/kia.png',
    'land rover': 'assets/brands/png/land_rover.png',
    'cadillac': 'assets/brands/png/cadillac.png',
    'changan': 'assets/brands/png/changan.png',
  };

  String get _normalizedName => brand.name.trim().toLowerCase();

  String? _resolvePngAssetPath() => _pngAssetByName[_normalizedName];

  @override
  Widget build(BuildContext context) {
    final logoSize = 56 * scale;
    final pngPath = _resolvePngAssetPath();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: logoSize,
          height: logoSize,
          child: pngPath != null
              ? Image.asset(
                  pngPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => _fallbackLabel(logoSize),
                )
              : brand.logo != null && brand.logo!.startsWith('http')
                  ? Image.network(
                      brand.logo!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, _, _) => _fallbackLabel(logoSize),
                    )
                  : _fallbackLabel(logoSize),
        ),
        SizedBox(height: 6 * scale),
        SizedBox(
          width: logoSize + 16,
          child: MetallicSilverText(
            brand.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackLabel(double logoSize) {
    return Container(
      width: logoSize,
      height: logoSize,
      alignment: Alignment.center,
      child: MetallicSilverText(
        brand.name.isNotEmpty ? brand.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 20 * scale,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
