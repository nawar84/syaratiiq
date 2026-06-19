import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/src/core/utils/media_url.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.filterQuality = FilterQuality.low,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final FilterQuality filterQuality;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMediaUrl(url);
    if (resolved.isEmpty) {
      return errorBuilder?.call(context, 'empty-url', null) ??
          const Center(child: Icon(Icons.broken_image_outlined));
    }

    return Image.network(
      resolved,
      fit: fit,
      width: width,
      height: height,
      filterQuality: filterQuality,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      webHtmlElementStrategy:
          kIsWeb ? WebHtmlElementStrategy.prefer : WebHtmlElementStrategy.never,
    );
  }
}
