import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/src/core/network/api_client.dart';
import 'package:mobile/src/core/network/multipart_utils.dart';
import 'package:mobile/src/features/cars/domain/entities/car_management_entities.dart';

class CarManagementRemoteDataSource {
  CarManagementRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<OwnerExhibition>> fetchMyExhibitions() async {
    final response = await _client.dio.get('/my/exhibitions');
    final list = response.data as List<dynamic>;
    return list.map((e) => OwnerExhibition.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CarBrand>> fetchBrands() async {
    final response = await _client.dio.get('/brands');
    final list = response.data as List<dynamic>;
    return list.map((e) => CarBrand.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<OwnerCar>> fetchMyCars() async {
    final response = await _client.dio.get('/my/cars');
    final list = response.data as List<dynamic>;
    return list.map((e) => OwnerCar.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createCar({
    int? exhibitionId,
    int? brandId,
    String? brandName,
    String? name,
    String? model,
    int? year,
    double? price,
    String? description,
    List<XFile> images = const [],
    String? color,
    int? mileage,
    String? fuelType,
    String? transmission,
    String? damageNotes,
  }) async {
    final form = await _buildFormData(
      fields: {
        if (exhibitionId != null) 'exhibition_id': exhibitionId,
        if (brandId != null) 'brand_id': brandId,
        if (brandId == null && brandName != null && brandName.isNotEmpty) 'brand': brandName,
        if (name != null && name.isNotEmpty) ...{'name': name, 'title': name},
        if (model != null && model.isNotEmpty) 'model': model,
        if (year != null) 'year': year,
        if (price != null) 'price': price,
        if (description != null && description.isNotEmpty) 'description': description,
        if (color != null && color.isNotEmpty) 'color': color,
        if (mileage != null) 'mileage': mileage,
        if (fuelType != null && fuelType.isNotEmpty) 'fuel_type': fuelType,
        if (transmission != null && transmission.isNotEmpty) 'transmission': transmission,
        if (damageNotes != null && damageNotes.isNotEmpty) 'damage_notes': damageNotes,
      },
      images: images,
    );
    await _client.dio.post('/cars', data: form);
  }

  Future<void> updateCar({
    required int id,
    int? brandId,
    String? brandName,
    required String name,
    required String model,
    required int year,
    required double price,
    required String description,
    required List<XFile> newImages,
    List<String> keepImages = const [],
    bool updateImages = false,
    String? color,
    int? mileage,
    String? fuelType,
    String? transmission,
    String? damageNotes,
  }) async {
    final form = await _buildFormData(
      fields: {
        if (brandId != null) 'brand_id': brandId,
        if (brandId == null && brandName != null && brandName.isNotEmpty) 'brand': brandName,
        'name': name,
        'title': name,
        'model': model,
        'year': year,
        'price': price,
        'description': description,
        if (color != null && color.isNotEmpty) 'color': color,
        if (mileage != null) 'mileage': mileage,
        if (fuelType != null && fuelType.isNotEmpty) 'fuel_type': fuelType,
        if (transmission != null && transmission.isNotEmpty) 'transmission': transmission,
        if (damageNotes != null && damageNotes.isNotEmpty) 'damage_notes': damageNotes,
        if (updateImages) 'update_images': 1,
      },
      images: newImages,
      keepImages: keepImages,
    );
    await _client.dio.post('/cars/$id?_method=PUT', data: form);
  }

  Future<void> deleteCar(int id) async {
    await _client.dio.delete('/cars/$id');
  }

  Future<FormData> _buildFormData({
    required Map<String, dynamic> fields,
    List<XFile> images = const [],
    List<String> keepImages = const [],
  }) async {
    final form = FormData();
    fields.forEach((key, value) {
      if (value != null) {
        form.fields.add(MapEntry(key, value.toString()));
      }
    });

    for (final imageUrl in keepImages) {
      form.fields.add(MapEntry('keep_images[]', imageUrl));
    }

    for (final image in images) {
      form.files.add(
        MapEntry(
          'images[]',
          await multipartFileFromXFile(
            image,
            filename: _imageFilename(image),
          ),
        ),
      );
    }

    return form;
  }

  String _imageFilename(XFile image) {
    final name = image.name.trim();
    if (name.isNotEmpty && name.contains('.')) {
      return name;
    }

    final extension = image.path.split('.').last.toLowerCase();
    const known = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};
    final suffix = known.contains(extension) ? extension : 'jpg';

    return 'car_${DateTime.now().millisecondsSinceEpoch}.$suffix';
  }
}
