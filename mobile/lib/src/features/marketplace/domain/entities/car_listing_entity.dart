class CarListingEntity {
  const CarListingEntity({
    required this.id,
    required this.title,
    required this.brandName,
    required this.model,
    required this.year,
    required this.price,
    required this.color,
    required this.mileage,
    required this.fuelType,
    required this.transmission,
    required this.description,
    required this.damageNotes,
    required this.imageUrls,
    required this.showroomName,
    required this.showroomPhone,
    required this.provinceName,
    required this.showroomId,
    required this.viewsCount,
  });

  final int id;
  final String title;
  final String brandName;
  final String model;
  final int year;
  final double price;
  final String color;
  final int mileage;
  final String fuelType;
  final String transmission;
  final String description;
  final String damageNotes;
  final List<String> imageUrls;
  final String showroomName;
  final String showroomPhone;
  final String provinceName;
  final int showroomId;
  final int viewsCount;

  factory CarListingEntity.fromJson(Map<String, dynamic> json) {
    final brand = json['brand'] as Map<String, dynamic>?;
    final exhibition = json['exhibition'] as Map<String, dynamic>?;
    final province = exhibition?['province'] as Map<String, dynamic>?;

    return CarListingEntity(
      id: json['id'] as int,
      title: (json['display_title'] ?? json['title'] ?? json['name'] ?? '') as String,
      brandName: brand?['name'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      price: double.tryParse('${json['price']}') ?? 0,
      color: json['color'] as String? ?? '',
      mileage: json['mileage'] as int? ?? 0,
      fuelType: json['fuel_type'] as String? ?? '',
      transmission: json['transmission'] as String? ?? '',
      description: json['description'] as String? ?? '',
      damageNotes: json['damage_notes'] as String? ?? '',
      imageUrls: List<String>.from(json['image_urls'] as List? ?? []),
      showroomName: exhibition?['name'] as String? ?? '',
      showroomPhone: exhibition?['phone'] as String? ?? '',
      provinceName: province?['name'] as String? ?? '',
      showroomId: exhibition?['id'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
    );
  }
}

class CarSearchFilters {
  const CarSearchFilters({
    this.search,
    this.provinceId,
    this.showroomId,
    this.brandId,
    this.brand,
    this.model,
    this.year,
    this.yearMin,
    this.yearMax,
    this.color,
    this.fuelType,
    this.transmission,
    this.priceMin,
    this.priceMax,
  });

  final String? search;
  final int? provinceId;
  final int? showroomId;
  final int? brandId;
  final String? brand;
  final String? model;
  final int? year;
  final int? yearMin;
  final int? yearMax;
  final String? color;
  final String? fuelType;
  final String? transmission;
  final double? priceMin;
  final double? priceMax;

  Map<String, dynamic> toQuery() {
    return {
      if (search != null && search!.isNotEmpty) 'search': search,
      if (provinceId != null) 'province_id': provinceId,
      if (showroomId != null) 'exhibition_id': showroomId,
      if (brandId != null) 'brand_id': brandId,
      if (brand != null && brand!.isNotEmpty) 'brand': brand,
      if (model != null && model!.isNotEmpty) 'model': model,
      if (year != null) 'year': year,
      if (yearMin != null) 'year_min': yearMin,
      if (yearMax != null) 'year_max': yearMax,
      if (color != null && color!.isNotEmpty) 'color': color,
      if (fuelType != null && fuelType!.isNotEmpty) 'fuel_type': fuelType,
      if (transmission != null && transmission!.isNotEmpty) 'transmission': transmission,
      if (priceMin != null) 'price_min': priceMin,
      if (priceMax != null) 'price_max': priceMax,
      'per_page': 100,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarSearchFilters &&
          search == other.search &&
          provinceId == other.provinceId &&
          showroomId == other.showroomId &&
          brandId == other.brandId &&
          brand == other.brand &&
          model == other.model &&
          year == other.year &&
          yearMin == other.yearMin &&
          yearMax == other.yearMax &&
          color == other.color &&
          fuelType == other.fuelType &&
          transmission == other.transmission &&
          priceMin == other.priceMin &&
          priceMax == other.priceMax;

  @override
  int get hashCode => Object.hash(
        search,
        provinceId,
        showroomId,
        brandId,
        brand,
        model,
        year,
        yearMin,
        yearMax,
        color,
        fuelType,
        transmission,
        priceMin,
        priceMax,
      );
}
