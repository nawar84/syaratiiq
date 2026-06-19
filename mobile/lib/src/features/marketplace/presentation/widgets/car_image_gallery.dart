import 'package:flutter/material.dart';
import 'package:mobile/src/core/widgets/app_network_image.dart';

class CarImageGallery extends StatefulWidget {
  const CarImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 240,
  });

  final List<String> imageUrls;
  final double height;

  @override
  State<CarImageGallery> createState() => _CarImageGalleryState();
}

class _CarImageGalleryState extends State<CarImageGallery> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openViewer(int index) {
    CarImageViewerScreen.open(
      context,
      imageUrls: widget.imageUrls,
      initialIndex: index,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.imageUrls.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (_, index) => GestureDetector(
                  onTap: () => _openViewer(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _NetworkImage(
                      url: widget.imageUrls[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'اضغط للتكبير',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.imageUrls.length > 1)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Text(
                        '${_currentIndex + 1}/${widget.imageUrls.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.imageUrls.length, (index) {
              final active = index == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFFF7A00) : const Color(0xFF4A5F8C),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class CarImageViewerScreen extends StatefulWidget {
  const CarImageViewerScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  final List<String> imageUrls;
  final int initialIndex;

  static Future<void> open(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CarImageViewerScreen(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  State<CarImageViewerScreen> createState() => _CarImageViewerScreenState();
}

class _CarImageViewerScreenState extends State<CarImageViewerScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _pageScrollEnabled = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onZoomChanged(bool zoomed) {
    if (_pageScrollEnabled == !zoomed) return;
    setState(() => _pageScrollEnabled = !zoomed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'إغلاق',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('${_currentIndex + 1} / ${widget.imageUrls.length}'),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: _pageScrollEnabled ? const PageScrollPhysics() : const NeverScrollableScrollPhysics(),
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() {
          _currentIndex = index;
          _pageScrollEnabled = true;
        }),
        itemBuilder: (_, index) => _ZoomableImage(
          url: widget.imageUrls[index],
          onZoomChanged: _onZoomChanged,
        ),
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({
    required this.url,
    required this.onZoomChanged,
  });

  final String url;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final TransformationController _controller = TransformationController();
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTransform);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTransform);
    _controller.dispose();
    super.dispose();
  }

  void _handleTransform() {
    final zoomed = _controller.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _isZoomed) return;
    _isZoomed = zoomed;
    widget.onZoomChanged(zoomed);
  }

  void _resetZoom() {
    _controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _resetZoom,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 4,
        panEnabled: true,
        child: Center(
          child: _NetworkImage(
            url: widget.url,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({
    required this.url,
    required this.fit,
  });

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return AppNetworkImage(
      url: url,
      fit: fit,
      width: fit == BoxFit.contain ? double.infinity : null,
      height: fit == BoxFit.contain ? double.infinity : null,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
        );
      },
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.broken_image_outlined, size: 48, color: Color(0xFF8A97BF)),
      ),
    );
  }
}
