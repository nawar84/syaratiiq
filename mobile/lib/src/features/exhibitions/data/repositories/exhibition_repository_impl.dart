import 'package:mobile/src/features/exhibitions/data/datasources/exhibition_remote_data_source.dart';
import 'package:mobile/src/features/exhibitions/domain/entities/province_entity.dart';
import 'package:mobile/src/features/exhibitions/domain/repositories/exhibition_repository.dart';
import 'package:image_picker/image_picker.dart';

class ExhibitionRepositoryImpl implements ExhibitionRepository {
  ExhibitionRepositoryImpl(this._remoteDataSource);

  final ExhibitionRemoteDataSource _remoteDataSource;

  @override
  Future<void> addExhibition({
    required String name,
    required String ownerName,
    required String phone,
    required int provinceId,
    required String address,
    XFile? logoFile,
    String? logoUrl,
    String? description,
  }) {
    return _remoteDataSource.addExhibition(
      name: name,
      ownerName: ownerName,
      phone: phone,
      provinceId: provinceId,
      address: address,
      logoFile: logoFile,
      logoUrl: logoUrl,
      description: description,
    );
  }

  @override
  Future<List<ProvinceEntity>> fetchProvinces() => _remoteDataSource.fetchProvinces();
}
