class OwnerExhibition {
  const OwnerExhibition({required this.id, required this.name, required this.phone});
  final int id;
  final String name;
  final String phone;

  factory OwnerExhibition.fromJson(Map<String, dynamic> json) {
    return OwnerExhibition(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
    );
  }
}

class CarBrand {
  const CarBrand({required this.id, required this.name});
  final int id;
  final String name;

  factory CarBrand.fromJson(Map<String, dynamic> json) {
    return CarBrand(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class OwnerCar {
  const OwnerCar({
    required this.id,
    required this.exhibitionId,
    required this.brandId,
    required this.exhibitionName,
    required this.brandName,
    required this.name,
    required this.model,
    required this.year,
    required this.price,
    required this.color,
    required this.mileage,
    required this.fuelType,
    required this.transmission,
    required this.description,
    required this.damageNotes,
    required this.images,
  });

  final int id;
  final int exhibitionId;
  final int brandId;
  final String exhibitionName;
  final String brandName;
  final String name;
  final String model;
  final int year;
  final double price;
  final String color;
  final int mileage;
  final String fuelType;
  final String transmission;
  final String description;
  final String damageNotes;
  final List<String> images;

  factory OwnerCar.fromJson(Map<String, dynamic> json) {
    final exhibition = json['exhibition'] as Map<String, dynamic>? ?? {};
    final brand = json['brand'] as Map<String, dynamic>? ?? {};
    final imageUrls = json['image_urls'] as List?;
    final imagesRaw = imageUrls ?? json['images'] as List<dynamic>? ?? <dynamic>[];
    return OwnerCar(
      id: json['id'] as int,
      exhibitionId: exhibition['id'] as int? ?? json['exhibition_id'] as int? ?? 0,
      brandId: brand['id'] as int? ?? json['brand_id'] as int? ?? 0,
      exhibitionName: exhibition['name'] as String? ?? '',
      brandName: brand['name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: _asInt(json['year']),
      price: _asDouble(json['price']),
      color: json['color'] as String? ?? '',
      mileage: _asInt(json['mileage']),
      fuelType: json['fuel_type'] as String? ?? '',
      transmission: json['transmission'] as String? ?? '',
      description: json['description'] as String? ?? '',
      damageNotes: json['damage_notes'] as String? ?? '',
      images: imagesRaw.map((e) => e.toString()).toList(),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
