import 'package:flutter/material.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';
import 'package:mobile/src/features/home/presentation/widgets/brand_logo_badge.dart';

class BrandsSection extends StatelessWidget {
  const BrandsSection({
    super.key,
    required this.brands,
    required this.scale,
  });

  final List<BrandEntity> brands;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MetallicSilverText(
          'أشهر الماركات',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22 * scale,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4 * scale),
        MetallicSilverText(
          'تصفح حسب العلامة التجارية',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 14 * scale),
        SizedBox(
          height: 96 * scale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 4 * scale),
            itemCount: brands.length,
            separatorBuilder: (_, _) => SizedBox(width: 12 * scale),
            itemBuilder: (context, index) {
              return BrandLogoBadge(
                brand: brands[index],
                scale: scale,
              );
            },
          ),
        ),
      ],
    );
  }
}
