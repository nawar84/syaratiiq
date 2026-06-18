import 'package:mobile/src/core/network/api_client.dart';
import 'package:mobile/src/features/marketplace/domain/entities/car_listing_entity.dart';
import 'package:mobile/src/features/marketplace/domain/entities/showroom_detail_entity.dart';
import 'package:mobile/src/features/marketplace/domain/entities/showroom_summary_entity.dart';
import 'package:mobile/src/features/marketplace/domain/repositories/marketplace_repository.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  MarketplaceRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<CarListingEntity>> fetchCars({CarSearchFilters? filters}) async {
    final response = await _client.dio.get('/cars', queryParameters: filters?.toQuery());
    final payload = response.data;
    final data = payload is Map ? payload['data'] as List? ?? [] : payload as List;
    return data.map((e) => CarListingEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<CarListingEntity> fetchCar(int id) async {
    final response = await _client.dio.get('/cars/$id');
    return CarListingEntity.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<CarListingEntity>> fetchFavorites() async {
    final response = await _client.dio.get('/favorites');
    final data = response.data as List;
    return data.map((e) => CarListingEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> addFavorite(int carId) async {
    await _client.dio.post('/favorites', data: {'car_id': carId});
  }

  @override
  Future<void> removeFavorite(int carId) async {
    await _client.dio.delete('/favorites/$carId');
  }

  @override
  Future<bool> isFavorite(int carId) async {
    final response = await _client.dio.get('/favorites/$carId/check');
    return response.data['is_favorite'] as bool? ?? false;
  }

  @override
  Future<ShowroomDetailEntity> fetchShowroom(int id) async {
    final response = await _client.dio.get('/showrooms/$id');
    return ShowroomDetailEntity.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<ShowroomSummaryEntity>> fetchShowrooms({ShowroomSearchFilters? filters}) async {
    final response = await _client.dio.get('/showrooms', queryParameters: filters?.toQuery() ?? {'per_page': 100});
    final payload = response.data as Map<String, dynamic>;
    final data = payload['data'] as List? ?? [];
    return data.map((e) => ShowroomSummaryEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> trackPhoneClick(int carId) async {
    await _client.dio.post('/cars/$carId/track-phone');
  }

  @override
  Future<void> trackWhatsAppClick(int carId) async {
    await _client.dio.post('/cars/$carId/track-whatsapp');
  }

  @override
  Future<OwnerAnalyticsEntity> fetchOwnerAnalytics() async {
    final response = await _client.dio.get('/my/cars/stats');
    return OwnerAnalyticsEntity.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SubscriptionStatusEntity> fetchSubscriptionStatus(int showroomId) async {
    final response = await _client.dio.get('/showrooms/$showroomId/subscription');
    return SubscriptionStatusEntity.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> renewSubscription(int showroomId, {double? amount}) async {
    await _client.dio.post('/showrooms/$showroomId/renew', data: {
      if (amount != null) 'amount': amount,
    });
  }
}
