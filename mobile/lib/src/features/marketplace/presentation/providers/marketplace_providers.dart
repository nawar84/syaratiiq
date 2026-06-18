import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/src/features/home/presentation/providers/home_providers.dart';
import 'package:mobile/src/features/marketplace/data/repositories/marketplace_repository_impl.dart';
import 'package:mobile/src/features/marketplace/domain/entities/car_listing_entity.dart';
import 'package:mobile/src/features/marketplace/domain/entities/showroom_detail_entity.dart';
import 'package:mobile/src/features/marketplace/domain/entities/showroom_summary_entity.dart';
import 'package:mobile/src/features/marketplace/domain/repositories/marketplace_repository.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepositoryImpl(ref.watch(apiClientProvider));
});

final latestCarsProvider = FutureProvider.autoDispose<List<CarListingEntity>>((ref) async {
  return ref.read(marketplaceRepositoryProvider).fetchCars();
});

final carDetailProvider = FutureProvider.autoDispose.family<CarListingEntity, int>((ref, id) async {
  return ref.read(marketplaceRepositoryProvider).fetchCar(id);
});

final favoritesProvider = FutureProvider.autoDispose<List<CarListingEntity>>((ref) async {
  return ref.read(marketplaceRepositoryProvider).fetchFavorites();
});

final carSearchProvider =
    FutureProvider.autoDispose.family<List<CarListingEntity>, CarSearchFilters>((ref, filters) async {
  return ref.read(marketplaceRepositoryProvider).fetchCars(filters: filters);
});

final isFavoriteProvider = FutureProvider.autoDispose.family<bool, int>((ref, carId) async {
  return ref.read(marketplaceRepositoryProvider).isFavorite(carId);
});

final showroomDetailProvider =
    FutureProvider.autoDispose.family<ShowroomDetailEntity, int>((ref, id) async {
  return ref.read(marketplaceRepositoryProvider).fetchShowroom(id);
});

final subscriptionStatusProvider =
    FutureProvider.autoDispose.family<SubscriptionStatusEntity, int>((ref, showroomId) async {
  return ref.read(marketplaceRepositoryProvider).fetchSubscriptionStatus(showroomId);
});

final showroomsListProvider = FutureProvider.autoDispose
    .family<List<ShowroomSummaryEntity>, ShowroomSearchFilters>((ref, filters) async {
  return ref.read(marketplaceRepositoryProvider).fetchShowrooms(filters: filters);
});

final ownerAnalyticsProvider = FutureProvider.autoDispose<OwnerAnalyticsEntity>((ref) async {
  return ref.read(marketplaceRepositoryProvider).fetchOwnerAnalytics();
});
