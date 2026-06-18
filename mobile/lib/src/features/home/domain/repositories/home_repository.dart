import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';
import 'package:mobile/src/features/home/domain/entities/exhibition_entity.dart';
import 'package:mobile/src/features/home/domain/entities/statistics_entity.dart';

abstract class HomeRepository {
  Future<StatisticsEntity> fetchStatistics();
  Future<List<BrandEntity>> fetchBrands();
  Future<List<ExhibitionEntity>> fetchExhibitions();
}
