class BrandEntity {
  const BrandEntity({
    required this.id,
    required this.name,
    this.logo,
  });

  final int id;
  final String name;
  final String? logo;

  factory BrandEntity.fromJson(Map<String, dynamic> json) {
    return BrandEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      logo: json['logo'] as String?,
    );
  }
}
