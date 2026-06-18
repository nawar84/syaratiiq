class ProvinceEntity {
  const ProvinceEntity({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory ProvinceEntity.fromJson(Map<String, dynamic> json) {
    return ProvinceEntity(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
