import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/src/core/auth/app_roles.dart';
import 'package:mobile/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/src/features/cars/data/datasources/car_management_remote_data_source.dart';
import 'package:mobile/src/features/cars/domain/entities/car_management_entities.dart';
import 'package:mobile/src/features/home/presentation/providers/home_providers.dart';

final carRemoteDataSourceProvider = Provider<CarManagementRemoteDataSource>(
  (ref) => CarManagementRemoteDataSource(ref.watch(apiClientProvider)),
);

final myExhibitionsProvider = FutureProvider<List<OwnerExhibition>>(
  (ref) => ref.read(carRemoteDataSourceProvider).fetchMyExhibitions(),
);

final myShowroomIdsProvider = FutureProvider<Set<int>>((ref) async {
  final session = ref.watch(authSessionProvider).asData?.value;
  if (session == null || !AppRoles.isSeller(session.role)) {
    return {};
  }
  final exhibitions = await ref.read(myExhibitionsProvider.future);
  return exhibitions.map((e) => e.id).toSet();
});

final carBrandsProvider = FutureProvider<List<CarBrand>>(
  (ref) => ref.read(carRemoteDataSourceProvider).fetchBrands(),
);

final myCarsProvider = FutureProvider<List<OwnerCar>>(
  (ref) => ref.read(carRemoteDataSourceProvider).fetchMyCars(),
);

final createCarProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, payload) async {
  await ref.read(carRemoteDataSourceProvider).createCar(
        exhibitionId: payload['exhibition_id'] as int,
        brandId: payload['brand_id'] as int,
        name: payload['name'] as String,
        model: payload['model'] as String,
        year: payload['year'] as int,
        price: payload['price'] as double,
        description: payload['description'] as String,
        images: payload['images'] as List<XFile>,
      );
  ref.invalidate(myCarsProvider);
  ref.invalidate(statisticsProvider);
});

final updateCarProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, payload) async {
  await ref.read(carRemoteDataSourceProvider).updateCar(
        id: payload['id'] as int,
        brandId: payload['brand_id'] as int?,
        brandName: payload['brand'] as String?,
        name: payload['name'] as String,
        model: payload['model'] as String,
        year: payload['year'] as int,
        price: payload['price'] as double,
        description: payload['description'] as String,
        newImages: payload['images'] as List<XFile>,
        keepImages: (payload['keep_images'] as List<String>?) ?? const [],
      );
  ref.invalidate(myCarsProvider);
});
