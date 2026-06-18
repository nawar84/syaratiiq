import 'package:mobile/src/features/marketplace/domain/entities/car_listing_entity.dart';
import 'package:mobile/src/features/marketplace/domain/entities/showroom_detail_entity.dart';
import 'package:mobile/src/features/marketplace/domain/entities/showroom_summary_entity.dart';

abstract class MarketplaceRepository {
  Future<List<CarListingEntity>> fetchCars({CarSearchFilters? filters});
  Future<CarListingEntity> fetchCar(int id);
  Future<List<CarListingEntity>> fetchFavorites();
  Future<void> addFavorite(int carId);
  Future<void> removeFavorite(int carId);
  Future<bool> isFavorite(int carId);
  Future<List<ShowroomSummaryEntity>> fetchShowrooms({ShowroomSearchFilters? filters});
  Future<ShowroomDetailEntity> fetchShowroom(int id);
  Future<void> trackPhoneClick(int carId);
  Future<void> trackWhatsAppClick(int carId);
  Future<OwnerAnalyticsEntity> fetchOwnerAnalytics();
  Future<SubscriptionStatusEntity> fetchSubscriptionStatus(int showroomId);
  Future<void> renewSubscription(int showroomId, {double? amount});
}
