import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/core/widgets/app_network_image.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:mobile/src/features/marketplace/presentation/screens/car_detail_screen.dart';
import 'package:mobile/src/features/marketplace/presentation/screens/cars_browse_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF061338), Color(0xFF030B24)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: favorites.when(
        data: (items) => items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_border, size: 48, color: Color(0xFF8A97BF)),
                    const SizedBox(height: 12),
                    const MetallicSilverText('لا توجد سيارات في المفضلة'),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      style: AppTheme.tonalButtonStyle,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CarsBrowseScreen()),
                      ),
                      child: const Text('تصفح السيارات'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(favoritesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final car = items[i];
                    return Dismissible(
                      key: ValueKey(car.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        color: Colors.redAccent,
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await ref.read(marketplaceRepositoryProvider).removeFavorite(car.id);
                        ref.invalidate(favoritesProvider);
                      },
                      child: Card(
                        color: const Color(0xFF0B1D48),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CarDetailScreen(carId: car.id)),
                          ),
                          leading: car.imageUrls.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AppNetworkImage(
                                    url: car.imageUrls.first,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.directions_car, color: Color(0xFF8A97BF)),
                          title: Text(car.title, textAlign: TextAlign.right, style: AppTheme.orangeTextStyle),
                          subtitle: Text(
                            '${car.year} • ${car.brandName} • \$${car.price.toStringAsFixed(0)}',
                            textAlign: TextAlign.right,
                            style: AppTheme.orangeTextStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          trailing: const Icon(Icons.favorite, color: Color(0xFFFF9412)),
                        ),
                      ),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: MetallicSilverText('خطأ: $e')),
      ),
    );
  }
}
