import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/network/api_client.dart';
import 'package:mobile/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/src/features/home/data/datasources/home_remote_data_source.dart';
import 'package:mobile/src/features/home/data/repositories/home_repository_impl.dart';
import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';
import 'package:mobile/src/features/home/domain/entities/exhibition_entity.dart';
import 'package:mobile/src/features/home/domain/entities/statistics_entity.dart';
import 'package:mobile/src/features/home/domain/repositories/home_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final session = ref.watch(authSessionProvider).asData?.value;
  return ApiClient(token: session?.token);
});

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>(
  (ref) => HomeRemoteDataSource(ref.watch(apiClientProvider)),
);

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(ref.read(homeRemoteDataSourceProvider)),
);

final statisticsProvider = FutureProvider<StatisticsEntity>(
  (ref) => ref.read(homeRepositoryProvider).fetchStatistics(),
);

final brandsProvider = FutureProvider<List<BrandEntity>>(
  (ref) => ref.read(homeRepositoryProvider).fetchBrands(),
);

final exhibitionsProvider = FutureProvider<List<ExhibitionEntity>>(
  (ref) => ref.read(homeRepositoryProvider).fetchExhibitions(),
);
