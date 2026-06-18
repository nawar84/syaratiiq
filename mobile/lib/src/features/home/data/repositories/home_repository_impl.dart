import 'package:mobile/src/features/home/data/datasources/home_remote_data_source.dart';
import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';
import 'package:mobile/src/features/home/domain/entities/exhibition_entity.dart';
import 'package:mobile/src/features/home/domain/entities/statistics_entity.dart';
import 'package:mobile/src/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remoteDataSource);

  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<List<BrandEntity>> fetchBrands() => _remoteDataSource.fetchBrands();

  @override
  Future<List<ExhibitionEntity>> fetchExhibitions() => _remoteDataSource.fetchExhibitions();

  @override
  Future<StatisticsEntity> fetchStatistics() => _remoteDataSource.fetchStatistics();
}
