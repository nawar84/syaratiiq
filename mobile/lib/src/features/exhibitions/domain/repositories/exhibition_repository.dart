import 'package:mobile/src/features/exhibitions/domain/entities/province_entity.dart';
import 'package:image_picker/image_picker.dart';

abstract class ExhibitionRepository {
  Future<List<ProvinceEntity>> fetchProvinces();
  Future<void> addExhibition({
    required String name,
    required String ownerName,
    required String phone,
    required int provinceId,
    required String address,
    XFile? logoFile,
    String? logoUrl,
    String? description,
  });
  Future<void> updateExhibition({
    required int id,
    required String name,
    required String ownerName,
    required String phone,
    XFile? logoFile,
    bool removeLogo = false,
  });
}
