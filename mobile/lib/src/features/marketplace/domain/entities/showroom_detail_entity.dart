import 'package:mobile/src/features/marketplace/domain/entities/car_listing_entity.dart';

class ShowroomDetailEntity {
  const ShowroomDetailEntity({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.description,
    required this.logoUrl,
    required this.coverImageUrl,
    required this.provinceName,
    required this.viewsCount,
    required this.carsCount,
    required this.cars,
  });

  final int id;
  final String name;
  final String ownerName;
  final String phone;
  final String address;
  final String description;
  final String? logoUrl;
  final String? coverImageUrl;
  final String provinceName;
  final int viewsCount;
  final int carsCount;
  final List<CarListingEntity> cars;

  factory ShowroomDetailEntity.fromJson(Map<String, dynamic> json) {
    final province = json['province'] as Map<String, dynamic>?;
    final carsJson = json['cars'] as List? ?? [];

    return ShowroomDetailEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      ownerName: json['owner_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      description: json['description'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? json['logo'] as String?,
      coverImageUrl: json['cover_image_url'] as String? ?? json['cover_image'] as String?,
      provinceName: province?['name'] as String? ?? '',
      viewsCount: json['views_count'] as int? ?? 0,
      carsCount: json['cars_count'] as int? ?? carsJson.length,
      cars: carsJson
          .map((e) => CarListingEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubscriptionStatusEntity {
  const SubscriptionStatusEntity({
    required this.showroomId,
    required this.isActive,
    required this.canManageCars,
    this.expiresAt,
    this.plan,
    this.amount,
  });

  final int showroomId;
  final bool isActive;
  final bool canManageCars;
  final DateTime? expiresAt;
  final String? plan;
  final double? amount;

  factory SubscriptionStatusEntity.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'] as Map<String, dynamic>?;
    return SubscriptionStatusEntity(
      showroomId: json['showroom_id'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? false,
      canManageCars: json['can_manage_cars'] as bool? ?? false,
      expiresAt: sub?['ends_at'] != null ? DateTime.tryParse('${sub!['ends_at']}') : null,
      plan: sub?['plan'] as String?,
      amount: sub?['amount'] != null ? double.tryParse('${sub!['amount']}') : null,
    );
  }
}
