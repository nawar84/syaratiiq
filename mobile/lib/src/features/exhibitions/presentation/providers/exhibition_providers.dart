import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/features/exhibitions/data/datasources/exhibition_remote_data_source.dart';
import 'package:mobile/src/features/exhibitions/data/repositories/exhibition_repository_impl.dart';
import 'package:mobile/src/features/exhibitions/domain/entities/province_entity.dart';
import 'package:mobile/src/features/exhibitions/domain/repositories/exhibition_repository.dart';
import 'package:mobile/src/features/home/presentation/providers/home_providers.dart';

final exhibitionRemoteProvider = Provider<ExhibitionRemoteDataSource>(
  (ref) => ExhibitionRemoteDataSource(ref.watch(apiClientProvider)),
);

final exhibitionRepositoryProvider = Provider<ExhibitionRepository>(
  (ref) => ExhibitionRepositoryImpl(ref.watch(exhibitionRemoteProvider)),
);

final provincesProvider = FutureProvider<List<ProvinceEntity>>(
  (ref) => ref.read(exhibitionRepositoryProvider).fetchProvinces(),
);

final addExhibitionProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, payload) async {
  await ref.read(exhibitionRepositoryProvider).addExhibition(
        name: payload['name'] as String,
        ownerName: payload['owner_name'] as String,
        phone: payload['phone'] as String,
        provinceId: payload['province_id'] as int,
        address: payload['address'] as String,
        logoFile: payload['logo_file'],
        logoUrl: payload['logo_url'] as String?,
        description: payload['description'] as String?,
      );
  ref.invalidate(exhibitionsProvider);
  ref.invalidate(statisticsProvider);
});
