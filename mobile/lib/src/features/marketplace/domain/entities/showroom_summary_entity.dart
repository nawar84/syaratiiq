class ShowroomSummaryEntity {
  const ShowroomSummaryEntity({
    required this.id,
    required this.name,
    required this.provinceName,
    required this.address,
    required this.logoUrl,
    required this.coverImageUrl,
    required this.carsCount,
  });

  final int id;
  final String name;
  final String provinceName;
  final String address;
  final String? logoUrl;
  final String? coverImageUrl;
  final int carsCount;

  factory ShowroomSummaryEntity.fromJson(Map<String, dynamic> json) {
    final province = json['province'] as Map<String, dynamic>?;
    return ShowroomSummaryEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      provinceName: province?['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? json['logo'] as String?,
      coverImageUrl: json['cover_image_url'] as String? ?? json['cover_image'] as String?,
      carsCount: json['cars_count'] as int? ?? 0,
    );
  }
}

class ShowroomSearchFilters {
  const ShowroomSearchFilters({
    this.search,
    this.provinceId,
    this.brand,
    this.model,
    this.color,
  });

  final String? search;
  final int? provinceId;
  final String? brand;
  final String? model;
  final String? color;

  Map<String, dynamic> toQuery() {
    return {
      if (search != null && search!.isNotEmpty) 'search': search,
      if (provinceId != null) 'province_id': provinceId,
      if (brand != null && brand!.isNotEmpty) 'brand': brand,
      if (model != null && model!.isNotEmpty) 'model': model,
      if (color != null && color!.isNotEmpty) 'color': color,
      'per_page': 100,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShowroomSearchFilters &&
          search == other.search &&
          provinceId == other.provinceId &&
          brand == other.brand &&
          model == other.model &&
          color == other.color;

  @override
  int get hashCode => Object.hash(search, provinceId, brand, model, color);
}

class OwnerAnalyticsEntity {
  const OwnerAnalyticsEntity({
    required this.totalCars,
    required this.totalViews,
    required this.totalPhoneClicks,
    required this.totalWhatsappClicks,
    required this.cars,
  });

  final int totalCars;
  final int totalViews;
  final int totalPhoneClicks;
  final int totalWhatsappClicks;
  final List<CarAnalyticsItem> cars;

  factory OwnerAnalyticsEntity.fromJson(Map<String, dynamic> json) {
    final carsJson = json['cars'] as List? ?? [];
    return OwnerAnalyticsEntity(
      totalCars: json['total_cars'] as int? ?? 0,
      totalViews: json['total_views'] as int? ?? 0,
      totalPhoneClicks: json['total_phone_clicks'] as int? ?? 0,
      totalWhatsappClicks: json['total_whatsapp_clicks'] as int? ?? 0,
      cars: carsJson.map((e) => CarAnalyticsItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class CarAnalyticsItem {
  const CarAnalyticsItem({
    required this.id,
    required this.title,
    required this.brandName,
    required this.showroomName,
    required this.viewsCount,
    required this.phoneClicksCount,
    required this.whatsappClicksCount,
  });

  final int id;
  final String title;
  final String brandName;
  final String showroomName;
  final int viewsCount;
  final int phoneClicksCount;
  final int whatsappClicksCount;

  factory CarAnalyticsItem.fromJson(Map<String, dynamic> json) {
    return CarAnalyticsItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      brandName: json['brand_name'] as String? ?? '',
      showroomName: json['showroom_name'] as String? ?? '',
      viewsCount: json['views_count'] as int? ?? 0,
      phoneClicksCount: json['phone_clicks_count'] as int? ?? 0,
      whatsappClicksCount: json['whatsapp_clicks_count'] as int? ?? 0,
    );
  }
}
