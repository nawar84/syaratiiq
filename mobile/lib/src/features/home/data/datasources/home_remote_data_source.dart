import 'package:mobile/src/core/network/api_client.dart';
import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';
import 'package:mobile/src/features/home/domain/entities/exhibition_entity.dart';
import 'package:mobile/src/features/home/domain/entities/statistics_entity.dart';

class HomeRemoteDataSource {
  HomeRemoteDataSource(this._client);

  final ApiClient _client;

  Future<StatisticsEntity> fetchStatistics() async {
    final response = await _client.dio.get('/statistics');
    return StatisticsEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<BrandEntity>> fetchBrands() async {
    final response = await _client.dio.get('/brands');
    final list = response.data as List<dynamic>;
    return list.map((item) => BrandEntity.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<ExhibitionEntity>> fetchExhibitions() async {
    final response = await _client.dio.get('/exhibitions');
    final payload = response.data as Map<String, dynamic>;
    final list = payload['data'] as List<dynamic>? ?? <dynamic>[];
    return list
        .map((item) => ExhibitionEntity.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
