import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/src/core/network/api_client.dart';
import 'package:mobile/src/features/exhibitions/domain/entities/province_entity.dart';

class ExhibitionRemoteDataSource {
  ExhibitionRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<ProvinceEntity>> fetchProvinces() async {
    try {
      final response = await _client.dio.get('/provinces');
      final list = response.data as List<dynamic>;
      return list.map((item) => ProvinceEntity.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException {
      const fixed = [
        'بغداد',
        'البصرة',
        'نينوى',
        'أربيل',
        'السليمانية',
        'دهوك',
        'كركوك',
        'الأنبار',
        'بابل',
        'كربلاء',
        'النجف',
        'واسط',
        'ديالى',
        'صلاح الدين',
        'المثنى',
        'ذي قار',
        'ميسان',
        'القادسية',
      ];
      return fixed
          .asMap()
          .entries
          .map((entry) => ProvinceEntity(id: entry.key + 1, name: entry.value))
          .toList();
    }
  }

  Future<void> addExhibition({
    required String name,
    required String ownerName,
    required String phone,
    required int provinceId,
    required String address,
    XFile? logoFile,
    String? logoUrl,
    String? description,
  }) async {
    final fields = <String, dynamic>{
      'name': name,
      'owner_name': ownerName,
      'phone': phone,
      'province_id': provinceId,
      'address': address,
    };

    if (logoUrl != null && logoUrl.isNotEmpty) {
      fields['logo_url'] = logoUrl;
    }
    if (description != null && description.isNotEmpty) {
      fields['description'] = description;
    }

    final form = FormData.fromMap(fields);

    if (logoFile != null) {
      form.files.add(
        MapEntry(
          'logo',
          await MultipartFile.fromFile(logoFile.path, filename: logoFile.name),
        ),
      );
    }

    await _client.dio.post('/exhibitions', data: form);
  }
}
