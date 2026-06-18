import 'package:flutter/material.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/features/marketplace/domain/entities/car_listing_entity.dart';

class CarStudioCard extends StatelessWidget {
  const CarStudioCard({
    super.key,
    required this.car,
    required this.onTap,
  });

  final CarListingEntity car;
  final VoidCallback onTap;

  String? get _imageUrl => car.imageUrls.isNotEmpty ? car.imageUrls.first : null;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF0B1D48),
            border: Border.all(color: const Color(0xFF8FA3D1).withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: _CarStudioImage(imageUrl: _imageUrl),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      car.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTheme.orangeTextStyle.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (car.year > 0) '${car.year}',
                        if (car.brandName.isNotEmpty) car.brandName,
                        if (car.price > 0) '\$${car.price.toStringAsFixed(0)}',
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTheme.orangeTextStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarStudioImage extends StatelessWidget {
  const _CarStudioImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const _CarStudioImagePlaceholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const _CarStudioImagePlaceholder(showProgress: true);
        },
      );
    }

    return const _CarStudioImagePlaceholder();
  }
}

class _CarStudioImagePlaceholder extends StatelessWidget {
  const _CarStudioImagePlaceholder({this.showProgress = false});

  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF152A55), Color(0xFF0A1638)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: showProgress
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.directions_car_outlined, color: Color(0xFF8A97BF), size: 42),
      ),
    );
  }
}
