import 'package:flutter/material.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/core/widgets/app_network_image.dart';
import 'package:mobile/src/features/marketplace/domain/entities/showroom_summary_entity.dart';

class ShowroomCard extends StatelessWidget {
  const ShowroomCard({
    super.key,
    required this.showroom,
    required this.onTap,
  });

  final ShowroomSummaryEntity showroom;
  final VoidCallback onTap;

  String? get _imageUrl => showroom.coverImageUrl ?? showroom.logoUrl;

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
                  child: _ShowroomImage(imageUrl: _imageUrl),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      showroom.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTheme.orangeTextStyle.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    if (showroom.provinceName.isNotEmpty || showroom.carsCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (showroom.provinceName.isNotEmpty) showroom.provinceName,
                          if (showroom.carsCount > 0) '${showroom.carsCount} سيارة',
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTheme.orangeTextStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
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

class _ShowroomImage extends StatelessWidget {
  const _ShowroomImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return AppNetworkImage(
        url: imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const _ShowroomImagePlaceholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const _ShowroomImagePlaceholder(showProgress: true);
        },
      );
    }

    return const _ShowroomImagePlaceholder();
  }
}

class _ShowroomImagePlaceholder extends StatelessWidget {
  const _ShowroomImagePlaceholder({this.showProgress = false});

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
            : const Icon(Icons.storefront_outlined, color: Color(0xFF8A97BF), size: 42),
      ),
    );
  }
}
